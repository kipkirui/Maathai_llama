#include <jni.h>

#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>
#include <queue>
#include <condition_variable>
#include <atomic>
#include <algorithm>

#include <android/log.h>

#include "llama.h"

namespace {

struct LlamaSession {
    llama_model * model = nullptr;
    llama_context * ctx = nullptr;
    llama_sampler * sampler = nullptr;
    std::mutex mutex;
    // sampler params
    float temperature = 0.7f;
    int top_k = 40;
    float top_p = 0.95f;
    // streaming / cancel
    bool cancel = false;
    std::thread worker;
    bool small_model = false;
    uint64_t model_params = 0;
    int tuned_ctx = 0;
    int tuned_threads = 0;
    int tuned_threads_batch = 0;
    int tuned_batch = 0;
};

std::unique_ptr<LlamaSession> g_session;

// logging helpers
#define LOG_TAG "MaathaiLL-NATIVE"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

constexpr int kUnboundedSafetyCap = 1024;

int resolve_target_tokens(int requested, int prompt_tokens) {
    if (requested > 0) {
        return requested;
    }
    if (!g_session || g_session->ctx == nullptr) {
        return kUnboundedSafetyCap;
    }
    const int ctx_slots = llama_n_ctx(g_session->ctx);
    int available = ctx_slots - prompt_tokens;
    if (available <= 0) {
        return 1;
    }
    return std::min(kUnboundedSafetyCap, available);
}

inline void ensure_backend() {
    static std::once_flag init_flag;
    std::call_once(init_flag, []() {
        llama_backend_init();
    });
}

void free_session() {
    if (!g_session) {
        return;
    }
    {
        std::lock_guard<std::mutex> lock(g_session->mutex);
        if (g_session->worker.joinable()) {
            g_session->cancel = true;
        }
    }
    if (g_session->worker.joinable()) {
        LOGI("Joining background worker before freeing session");
        g_session->worker.join();
    }

    std::lock_guard<std::mutex> lock(g_session->mutex);
    if (g_session->sampler != nullptr) {
        llama_sampler_free(g_session->sampler);
        g_session->sampler = nullptr;
    }
    if (g_session->ctx != nullptr) {
        llama_free(g_session->ctx);
        g_session->ctx = nullptr;
    }
    if (g_session->model != nullptr) {
        llama_model_free(g_session->model);
        g_session->model = nullptr;
    }
    g_session.reset();
}

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_initBackend(
    JNIEnv * env,
    jobject /* thiz */) {
    (void) env;
    ensure_backend();
    LOGI("initBackend() called");
    return JNI_TRUE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_loadModel(
    JNIEnv * env,
    jobject /* thiz */,
    jstring model_path,
    jint n_ctx,
    jint n_threads,
    jint n_gpu_layers,
    jfloat temperature,
    jint top_k,
    jfloat top_p,
    jfloat min_p,
    jfloat typical_p,
    jfloat top_n_sigma,
    jint mirostat_type,
    jfloat mirostat_tau,
    jfloat mirostat_eta,
    jfloat repeat_penalty,
    jfloat frequency_penalty,
    jfloat presence_penalty,
    jint repeat_last_n,
    jint min_keep) {
    ensure_backend();

    const char * c_path = env->GetStringUTFChars(model_path, nullptr);
    std::string path(c_path ? c_path : "");
    env->ReleaseStringUTFChars(model_path, c_path);

    if (path.empty()) {
        LOGE("loadModel(): empty path");
        return JNI_FALSE;
    }

    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = n_gpu_layers;

    free_session();

    auto session = std::make_unique<LlamaSession>();
    LOGI("loadModel(): loading %s", path.c_str());
    session->model = llama_model_load_from_file(path.c_str(), model_params);
    if (session->model == nullptr) {
        LOGE("loadModel(): llama_model_load_from_file failed");
        return JNI_FALSE;
    }

    llama_context_params ctx_params = llama_context_default_params();

    constexpr uint64_t kSmallModelParamLimit = 2000000000ULL; // 2B params
    constexpr int kSmallModelCtxDefault = 1024;
    constexpr int kSmallModelCtxCap = 2048;
    constexpr int kSmallModelThreadCeil = 4;
    constexpr int kSmallModelBatch = 32;
    constexpr int kDefaultCtxFallback = 4096;
    constexpr int kDefaultBatch = 64;

    session->model_params = llama_model_n_params(session->model);
    session->small_model = session->model_params > 0 && session->model_params <= kSmallModelParamLimit;

    const unsigned hw_concurrency = std::max(1u, std::thread::hardware_concurrency());

    int tuned_ctx = n_ctx;
    if (tuned_ctx <= 0) {
        tuned_ctx = session->small_model ? kSmallModelCtxDefault : kDefaultCtxFallback;
    }
    if (session->small_model && tuned_ctx > kSmallModelCtxCap) {
        LOGI("loadModel(): clamping context length to %d for small model", kSmallModelCtxCap);
        tuned_ctx = kSmallModelCtxCap;
    }

    int tuned_threads = n_threads > 0 ? n_threads : static_cast<int>(hw_concurrency);
    if (session->small_model && n_threads <= 0) {
        tuned_threads = static_cast<int>(std::min<unsigned>(hw_concurrency, kSmallModelThreadCeil));
        if (hw_concurrency >= 2 && tuned_threads < 2) {
            tuned_threads = 2;
        }
        if (tuned_threads <= 0) {
            tuned_threads = 1;
        }
    }
    if (tuned_threads <= 0) {
        tuned_threads = 1;
    }

    int tuned_threads_batch = tuned_threads;
    if (session->small_model) {
        tuned_threads_batch = std::max(1, tuned_threads / 2);
    }

    const int tuned_batch = session->small_model ? kSmallModelBatch : kDefaultBatch;

    ctx_params.n_ctx = tuned_ctx;
    ctx_params.n_threads = tuned_threads;
    ctx_params.n_threads_batch = tuned_threads_batch;
    ctx_params.n_batch = tuned_batch;
    ctx_params.no_perf = false;

    session->tuned_ctx = tuned_ctx;
    session->tuned_threads = tuned_threads;
    session->tuned_threads_batch = tuned_threads_batch;
    session->tuned_batch = tuned_batch;

    session->ctx = llama_init_from_model(session->model, ctx_params);
    if (session->ctx == nullptr) {
        llama_model_free(session->model);
        LOGE("loadModel(): llama_init_from_model failed");
        return JNI_FALSE;
    }

    // store sampler params
    session->temperature = temperature;
    session->top_k = top_k;
    session->top_p = top_p;

    auto sampler_params = llama_sampler_chain_default_params();
    session->sampler = llama_sampler_chain_init(sampler_params);
    // advanced samplers if provided (>0)
    if (min_p > 0.0f)        llama_sampler_chain_add(session->sampler, llama_sampler_init_min_p(min_p, (size_t) (min_keep > 0 ? min_keep : 1)));
    if (typical_p > 0.0f)    llama_sampler_chain_add(session->sampler, llama_sampler_init_typical(typical_p, (size_t) (min_keep > 0 ? min_keep : 1)));
    if (top_n_sigma > 0.0f)  llama_sampler_chain_add(session->sampler, llama_sampler_init_top_n_sigma(top_n_sigma));
    if (mirostat_type == 1)  llama_sampler_chain_add(session->sampler, llama_sampler_init_mirostat(llama_vocab_n_tokens(llama_model_get_vocab(session->model)), 0 /*seed*/, mirostat_tau > 0 ? mirostat_tau : 5.0f, mirostat_eta > 0 ? mirostat_eta : 0.1f, 100));
    if (mirostat_type == 2)  llama_sampler_chain_add(session->sampler, llama_sampler_init_mirostat_v2(0 /*seed*/, mirostat_tau > 0 ? mirostat_tau : 5.0f, mirostat_eta > 0 ? mirostat_eta : 0.1f));
    // core samplers
    llama_sampler_chain_add(session->sampler, llama_sampler_init_temp(session->temperature));
    llama_sampler_chain_add(session->sampler, llama_sampler_init_top_k(session->top_k));
    llama_sampler_chain_add(session->sampler, llama_sampler_init_top_p(session->top_p, (size_t) (min_keep > 0 ? min_keep : 1)));
    // RNG / distribution sampler is required for sampling
    llama_sampler_chain_add(session->sampler, llama_sampler_init_dist(0));
    if (repeat_penalty > 0.0f || frequency_penalty > 0.0f || presence_penalty > 0.0f) {
        auto * penalties = llama_sampler_init_penalties(
            (size_t) (repeat_last_n > 0 ? repeat_last_n : 64),
            repeat_penalty > 0.0f ? repeat_penalty : 1.0f,
            frequency_penalty > 0.0f ? frequency_penalty : 0.0f,
            presence_penalty > 0.0f ? presence_penalty : 0.0f
        );
        llama_sampler_chain_add(session->sampler, penalties);
    }

    g_session = std::move(session);
    LOGI("loadModel(): success (ctx=%u, threads=%d, threads_batch=%d, n_batch=%d, params=%llu, small=%d)",
         llama_n_ctx(g_session->ctx),
         g_session->tuned_threads,
         g_session->tuned_threads_batch,
         g_session->tuned_batch,
         static_cast<unsigned long long>(g_session->model_params),
         g_session->small_model ? 1 : 0);
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_generate(
    JNIEnv * env,
    jobject /* thiz */,
    jstring prompt,
    jint n_predict) {
    if (!g_session || g_session->ctx == nullptr) {
        LOGE("generate(): session/context not ready");
        return env->NewStringUTF("");
    }

    const char * c_prompt = env->GetStringUTFChars(prompt, nullptr);
    std::string prompt_text(c_prompt ? c_prompt : "");
    env->ReleaseStringUTFChars(prompt, c_prompt);

    std::lock_guard<std::mutex> lock(g_session->mutex);

    const llama_vocab * vocab = llama_model_get_vocab(g_session->model);

    llama_set_n_threads(g_session->ctx, llama_n_threads(g_session->ctx), llama_n_threads_batch(g_session->ctx));
    if (g_session->sampler == nullptr) {
        auto sampler_params = llama_sampler_chain_default_params();
        g_session->sampler = llama_sampler_chain_init(sampler_params);
        llama_sampler_chain_add(g_session->sampler, llama_sampler_init_temp(g_session->temperature));
        llama_sampler_chain_add(g_session->sampler, llama_sampler_init_top_k(g_session->top_k));
        llama_sampler_chain_add(g_session->sampler, llama_sampler_init_top_p(g_session->top_p, 1));
        llama_sampler_chain_add(g_session->sampler, llama_sampler_init_dist(0));
    } else {
        llama_sampler_reset(g_session->sampler);
    }

    // Apply chat template if available
    std::string final_prompt = prompt_text;
    {
        const char * tmpl = llama_model_chat_template(g_session->model, nullptr);
        if (tmpl != nullptr && *tmpl != '\0') {
            llama_chat_message msgs[1];
            msgs[0].role = "user";
            msgs[0].content = prompt_text.c_str();
            std::vector<char> buf(prompt_text.size() * 4 + 256);
            int32_t n = llama_chat_apply_template(tmpl, msgs, 1, true, buf.data(), (int32_t)buf.size());
            if (n > 0) {
                final_prompt.assign(buf.data(), (size_t)n);
            }
        }
    }

    const int n_prompt = -llama_tokenize(
        vocab,
        final_prompt.c_str(),
        final_prompt.size(),
        nullptr,
        0,
        true,
        true);

    if (n_prompt <= 0) {
        return env->NewStringUTF("");
    }

    std::vector<llama_token> tokens(static_cast<size_t>(n_prompt));
    if (llama_tokenize(
        vocab,
        final_prompt.c_str(),
        final_prompt.size(),
        tokens.data(),
        tokens.size(),
        true,
        true) < 0) {
        return env->NewStringUTF("");
    }

    llama_batch batch = llama_batch_get_one(tokens.data(), tokens.size());
    if (llama_decode(g_session->ctx, batch) != 0) {
        return env->NewStringUTF("");
    }

    std::string response;
    llama_token new_token = 0;
    int generated = 0;

    const int target_tokens = resolve_target_tokens(n_predict, n_prompt);
    while (generated < target_tokens) {
        new_token = llama_sampler_sample(g_session->sampler, g_session->ctx, -1);
        if (llama_vocab_is_eog(vocab, new_token)) {
            break;
        }

        char piece[256];
        int piece_len = llama_token_to_piece(vocab, new_token, piece, sizeof(piece), 0, true);
        if (piece_len <= 0) {
            break;
        }
        response.append(piece, piece_len);

        batch = llama_batch_get_one(&new_token, 1);
        if (llama_decode(g_session->ctx, batch) != 0) {
            break;
        }

        ++generated;
    }

    LOGI("generate(): done, tokens=%d", generated);
    return env->NewStringUTF(response.c_str());
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_updateSampler(
    JNIEnv * env,
    jobject /* thiz */,
    jfloat temperature,
    jint top_k,
    jfloat top_p,
    jfloat min_p,
    jfloat typical_p,
    jfloat top_n_sigma,
    jint mirostat_type,
    jfloat mirostat_tau,
    jfloat mirostat_eta,
    jfloat repeat_penalty,
    jfloat frequency_penalty,
    jfloat presence_penalty,
    jint repeat_last_n,
    jint min_keep) {
    (void) env;
    if (!g_session) return JNI_FALSE;
    std::lock_guard<std::mutex> lock(g_session->mutex);
    if (g_session->sampler != nullptr) {
        llama_sampler_free(g_session->sampler);
        g_session->sampler = nullptr;
    }
    g_session->temperature = temperature;
    g_session->top_k = top_k;
    g_session->top_p = top_p;
    auto sampler_params = llama_sampler_chain_default_params();
    g_session->sampler = llama_sampler_chain_init(sampler_params);
    if (min_p > 0.0f)        llama_sampler_chain_add(g_session->sampler, llama_sampler_init_min_p(min_p, (size_t) (min_keep > 0 ? min_keep : 1)));
    if (typical_p > 0.0f)    llama_sampler_chain_add(g_session->sampler, llama_sampler_init_typical(typical_p, (size_t) (min_keep > 0 ? min_keep : 1)));
    if (top_n_sigma > 0.0f)  llama_sampler_chain_add(g_session->sampler, llama_sampler_init_top_n_sigma(top_n_sigma));
    if (mirostat_type == 1)  llama_sampler_chain_add(g_session->sampler, llama_sampler_init_mirostat(llama_vocab_n_tokens(llama_model_get_vocab(g_session->model)), 0, mirostat_tau > 0 ? mirostat_tau : 5.0f, mirostat_eta > 0 ? mirostat_eta : 0.1f, 100));
    if (mirostat_type == 2)  llama_sampler_chain_add(g_session->sampler, llama_sampler_init_mirostat_v2(0, mirostat_tau > 0 ? mirostat_tau : 5.0f, mirostat_eta > 0 ? mirostat_eta : 0.1f));
    llama_sampler_chain_add(g_session->sampler, llama_sampler_init_temp(g_session->temperature));
    llama_sampler_chain_add(g_session->sampler, llama_sampler_init_top_k(g_session->top_k));
    llama_sampler_chain_add(g_session->sampler, llama_sampler_init_top_p(g_session->top_p, (size_t) (min_keep > 0 ? min_keep : 1)));
    llama_sampler_chain_add(g_session->sampler, llama_sampler_init_dist(0));
    return JNI_TRUE;
}

// Streaming state (producer-consumer queue)
static std::queue<std::string> g_stream_queue;
static std::mutex g_stream_mutex;
static std::condition_variable g_stream_cv;
static std::atomic_bool g_stream_active{false};

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_startGenerate(
    JNIEnv * env,
    jobject /* thiz */,
    jstring prompt,
    jint n_predict) {
    if (!g_session || g_session->ctx == nullptr) {
        LOGE("startGenerate(): session/context not ready");
        return JNI_FALSE;
    }
    const char * c_prompt = env->GetStringUTFChars(prompt, nullptr);
    std::string prompt_text(c_prompt ? c_prompt : "");
    env->ReleaseStringUTFChars(prompt, c_prompt);

    {
        std::lock_guard<std::mutex> lock(g_session->mutex);
        if (g_session->worker.joinable()) {
            LOGI("startGenerate(): joining previous worker");
            g_session->cancel = true;
        }
    }
    if (g_session->worker.joinable()) {
        g_session->worker.join();
    }

    // clear any previous queue content
    {
        std::lock_guard<std::mutex> ql(g_stream_mutex);
        while (!g_stream_queue.empty()) g_stream_queue.pop();
    }

    {
        std::lock_guard<std::mutex> lock(g_session->mutex);
        g_session->cancel = false;
        g_stream_active.store(true);
        // spawn producer
        g_session->worker = std::thread([prompt_text, n_predict]() {
            LOGI("[worker] start, promptLen=%zu, maxTokens=%d", prompt_text.size(), (int)n_predict);
            std::unique_lock<std::mutex> slock(g_session->mutex);
            const llama_vocab * vocab = llama_model_get_vocab(g_session->model);
            llama_set_n_threads(g_session->ctx, llama_n_threads(g_session->ctx), llama_n_threads_batch(g_session->ctx));
            llama_sampler_reset(g_session->sampler);

            // apply chat template
            std::string final_prompt = prompt_text;
            {
                const char * tmpl = llama_model_chat_template(g_session->model, nullptr);
                if (tmpl != nullptr && *tmpl != '\0') {
                    llama_chat_message msgs[1];
                    msgs[0].role = "user";
                    msgs[0].content = prompt_text.c_str();
                    std::vector<char> buf(prompt_text.size() * 4 + 256);
                    int32_t n = llama_chat_apply_template(tmpl, msgs, 1, true, buf.data(), (int32_t)buf.size());
                    if (n > 0) {
                        final_prompt.assign(buf.data(), (size_t)n);
                    }
                }
            }

            // tokenize
            int n_prompt = -llama_tokenize(vocab, final_prompt.c_str(), (int)final_prompt.size(), nullptr, 0, true, true);
            if (n_prompt <= 0) {
                LOGE("[worker] tokenize size failed: %d", n_prompt);
                g_stream_active.store(false);
                return;
            }
            std::vector<llama_token> tokens(static_cast<size_t>(n_prompt));
            if (llama_tokenize(vocab, final_prompt.c_str(), (int)final_prompt.size(), tokens.data(), (int)tokens.size(), true, true) < 0) {
                LOGE("[worker] tokenize failed");
                g_stream_active.store(false);
                return;
            }
            llama_batch batch = llama_batch_get_one(tokens.data(), (int)tokens.size());
            if (llama_decode(g_session->ctx, batch) != 0) {
                LOGE("[worker] decode prompt failed");
                g_stream_active.store(false);
                return;
            }

            int generated = 0;
            slock.unlock(); // allow nextTokenPiece to run while generating

            const int target_tokens = resolve_target_tokens(n_predict, n_prompt);
            while (generated < target_tokens) {
                {
                    std::lock_guard<std::mutex> lk(g_session->mutex);
                    if (g_session->cancel) {
                        LOGI("[worker] cancel requested");
                        break;
                    }
                }
                llama_token new_token = llama_sampler_sample(g_session->sampler, g_session->ctx, -1);
                if (llama_vocab_is_eog(vocab, new_token)) {
                    LOGI("[worker] EOG reached after %d tokens", generated);
                    break;
                }
                char piece[256];
                int piece_len = llama_token_to_piece(vocab, new_token, piece, sizeof(piece), 0, true);
                if (piece_len <= 0) {
                    LOGE("[worker] token_to_piece <= 0");
                    break;
                }
                {
                    std::lock_guard<std::mutex> ql(g_stream_mutex);
                    g_stream_queue.emplace(std::string(piece, (size_t)piece_len));
                }
                g_stream_cv.notify_all();

                llama_batch nb = llama_batch_get_one(&new_token, 1);
                if (llama_decode(g_session->ctx, nb) != 0) {
                    LOGE("[worker] decode next failed");
                    break;
                }
                ++generated;
            }
            LOGI("[worker] done, generated=%d", generated);
            g_stream_active.store(false);
            g_stream_cv.notify_all();
        });
    }

    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_nextTokenPiece(
    JNIEnv * env,
    jobject /* thiz */) {
    (void) env;
    if (!g_session) return nullptr;
    std::lock_guard<std::mutex> ql(g_stream_mutex);
    if (g_stream_queue.empty()) return nullptr;
    std::string next = std::move(g_stream_queue.front());
    g_stream_queue.pop();
    return env->NewStringUTF(next.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_cancelGenerate(
    JNIEnv * env,
    jobject /* thiz */) {
    (void) env;
    if (!g_session) return;
    std::lock_guard<std::mutex> lock(g_session->mutex);
    g_session->cancel = true;
    g_stream_active.store(false);
    g_stream_cv.notify_all();
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_isStreamActive(
    JNIEnv * env,
    jobject /* thiz */) {
    (void) env;
    return g_stream_active.load() ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_maathai_1llamma_MaathaiLlammaPlugin_release(
    JNIEnv * env,
    jobject /* thiz */) {
    (void) env;
    free_session();
}


