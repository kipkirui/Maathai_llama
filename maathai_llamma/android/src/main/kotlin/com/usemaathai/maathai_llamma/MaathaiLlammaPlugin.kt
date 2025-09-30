package com.usemaathai.maathai_llamma

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.io.File
import android.os.Handler
import android.os.Looper
import android.util.Log

class MaathaiLlammaPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        // Soft guard; tune per device class via Dart (defaults to 3.5 GB for 4-bit 7B models)
        private const val DEFAULT_MAX_MODEL_BYTES = 3_500L * 1024L * 1024L
        private const val TAG = "MaathaiLL"

        init {
            System.loadLibrary("maathai_llamma")
        }
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    @Volatile private var eventSink: EventChannel.EventSink? = null
    @Volatile private var streamingThread: Thread? = null
    private var maxModelBytes: Long = DEFAULT_MAX_MODEL_BYTES

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        channel = MethodChannel(binding.binaryMessenger, "maathai_llamma")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "maathai_llamma/events")
        eventChannel.setStreamHandler(this)
        val ok = initBackend()
        Log.i(TAG, "initBackend result: $ok")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine: cancelling and releasing")
        cancelAll()
        release()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "onMethodCall: ${call.method}")
        when (call.method) {
            "initialize" -> result.success(initBackend())

            "loadModel" -> handleLoadModel(call, result)

            "updateSampler" -> {
                Log.d(TAG, "updateSampler called")
                val temperature = (call.argument<Double>("temperature") ?: 0.7).toFloat()
                val topK = call.argument<Int>("topK") ?: 40
                val topP = (call.argument<Double>("topP") ?: 0.95).toFloat()
                val minP = (call.argument<Double>("minP") ?: -1.0).toFloat()
                val typicalP = (call.argument<Double>("typicalP") ?: -1.0).toFloat()
                val topNSigma = (call.argument<Double>("topNSigma") ?: -1.0).toFloat()
                val mirostatType = call.argument<Int>("mirostatType") ?: 0
                val mirostatTau = (call.argument<Double>("mirostatTau") ?: -1.0).toFloat()
                val mirostatEta = (call.argument<Double>("mirostatEta") ?: -1.0).toFloat()
                val repeatPenalty = (call.argument<Double>("repeatPenalty") ?: -1.0).toFloat()
                val frequencyPenalty = (call.argument<Double>("frequencyPenalty") ?: -1.0).toFloat()
                val presencePenalty = (call.argument<Double>("presencePenalty") ?: -1.0).toFloat()
                val repeatLastN = call.argument<Int>("repeatLastN") ?: -1
                val minKeep = call.argument<Int>("minKeep") ?: -1
                val ok = updateSampler(
                    temperature, topK, topP, minP, typicalP, topNSigma,
                    mirostatType, mirostatTau, mirostatEta,
                    repeatPenalty, frequencyPenalty, presencePenalty, repeatLastN, minKeep
                )
                Log.i(TAG, "updateSampler result: $ok")
                result.success(ok)
            }

            "startGenerateStream" -> {
                Log.i(TAG, "startGenerateStream called")
                val prompt = call.argument<String>("prompt")
                val maxTokens = call.argument<Int>("maxTokens") ?: 512
                if (prompt.isNullOrEmpty()) {
                    result.error("invalid_prompt", "prompt must not be empty", null)
                    return
                }

                // Ensure only one streaming thread
                cancelAll()

                streamingThread = Thread {
                    Log.i(TAG, "[stream] worker started, promptLen=${prompt.length}, maxTokens=$maxTokens")
                    val sink = eventSink
                    if (sink == null) {
                        Log.e(TAG, "[stream] No event stream listener attached")
                        Handler(Looper.getMainLooper()).post {
                            result.error("no_listener", "No event stream listener attached", null)
                        }
                        return@Thread
                    }
                    val ok = startGenerate(prompt, maxTokens)
                    Log.i(TAG, "[stream] startGenerate returned: $ok")
                    if (!ok) {
                        Handler(Looper.getMainLooper()).post {
                            sink.error("start_failed", "Failed to start generation", null)
                            result.success(false)
                        }
                        return@Thread
                    }
                    Handler(Looper.getMainLooper()).post { result.success(true) }
                    var tokenCount = 0
                    val main = Handler(Looper.getMainLooper())
                    val buffer = StringBuilder()
                    var lastFlush = System.currentTimeMillis()
                    val flush = {
                        if (buffer.isNotEmpty()) {
                            val text = buffer.toString()
                            buffer.clear()
                            main.post { sink.success(mapOf("type" to "token", "text" to text)) }
                        }
                    }
                    val FLUSH_EVERY_TOKENS = 4
                    val FLUSH_EVERY_MS = 30L
                    while (isStreamActive() || true) {
                        val piece = nextTokenPiece()
                        if (piece != null) {
                            tokenCount += 1
                            buffer.append(piece)
                            val now = System.currentTimeMillis()
                            if (tokenCount % FLUSH_EVERY_TOKENS == 0 || now - lastFlush >= FLUSH_EVERY_MS) {
                                if (tokenCount % (FLUSH_EVERY_TOKENS * 2) == 0) {
                                    Log.d(TAG, "[stream] tokens emitted=$tokenCount")
                                }
                                flush()
                                lastFlush = now
                            }
                        } else if (!isStreamActive()) {
                            break
                        } else {
                            try { Thread.sleep(8) } catch (_: InterruptedException) {}
                        }
                    }
                    // final flush
                    if (buffer.isNotEmpty()) {
                        val text = buffer.toString()
                        buffer.clear()
                        main.post { sink.success(mapOf("type" to "token", "text" to text)) }
                    }
                    Log.i(TAG, "[stream] done. totalTokens=$tokenCount")
                    Handler(Looper.getMainLooper()).post { sink.success(mapOf("type" to "done")) }
                }.also { it.start() }
            }

            "cancelGenerate" -> {
                Log.i(TAG, "cancelGenerate called")
                cancelAll()
                result.success(null)
            }

            "generate" -> {
                Log.i(TAG, "generate called")
                val prompt = call.argument<String>("prompt")
                val maxTokens = call.argument<Int>("maxTokens") ?: 512

                if (prompt.isNullOrEmpty()) {
                    result.error("invalid_prompt", "prompt must not be empty", null)
                    return
                }

                Thread {
                    Log.i(TAG, "[generate] begin, promptLen=${prompt.length}, maxTokens=$maxTokens")
                    val output = generate(prompt, maxTokens)
                    Log.i(TAG, "[generate] finished, outLen=${output.length}")
                    Handler(Looper.getMainLooper()).post {
                        result.success(output)
                    }
                }.start()
            }

            "release" -> {
                release()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i(TAG, "EventChannel onListen")
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.i(TAG, "EventChannel onCancel")
        eventSink = null
        cancelGenerate()
    }

    private fun handleLoadModel(call: MethodCall, result: Result) {
        val path = call.argument<String>("modelPath")
        val nCtx = call.argument<Int>("contextLength") ?: 4096
        val nThreads = call.argument<Int>("threads") ?: Runtime.getRuntime().availableProcessors()
        val nGpuLayers = call.argument<Int>("gpuLayers") ?: 0
        Log.i(TAG, "loadModel: path=$path ctx=$nCtx threads=$nThreads gpuLayers=$nGpuLayers")
        val temperature = (call.argument<Double>("temperature") ?: 0.7).toFloat()
        val topK = call.argument<Int>("topK") ?: 40
        val topP = (call.argument<Double>("topP") ?: 0.95).toFloat()
        val minP = (call.argument<Double>("minP") ?: -1.0).toFloat()
        val typicalP = (call.argument<Double>("typicalP") ?: -1.0).toFloat()
        val topNSigma = (call.argument<Double>("topNSigma") ?: -1.0).toFloat()
        val mirostatType = call.argument<Int>("mirostatType") ?: 0
        val mirostatTau = (call.argument<Double>("mirostatTau") ?: -1.0).toFloat()
        val mirostatEta = (call.argument<Double>("mirostatEta") ?: -1.0).toFloat()
        val repeatPenalty = (call.argument<Double>("repeatPenalty") ?: -1.0).toFloat()
        val frequencyPenalty = (call.argument<Double>("frequencyPenalty") ?: -1.0).toFloat()
        val presencePenalty = (call.argument<Double>("presencePenalty") ?: -1.0).toFloat()
        val repeatLastN = call.argument<Int>("repeatLastN") ?: -1
        val minKeep = call.argument<Int>("minKeep") ?: -1

        if (path.isNullOrBlank()) {
            result.error("invalid_path", "modelPath must be provided", null)
            return
        }

        val modelFile = File(path)
        if (!modelFile.exists()) {
            result.error("missing_file", "Model file not found at $path", null)
            return
        }

        val modelSize = runCatching { modelFile.length() }.getOrDefault(-1L)
        if (modelSize <= 0) {
            result.error("invalid_file", "Unable to determine model size", null)
            return
        }

        if (modelSize > maxModelBytes) {
            result.error(
                "model_too_large",
                "Model size ${(modelSize / (1024 * 1024)).toString()} MB exceeds ${maxModelBytes / (1024 * 1024)} MB guard",
                mapOf(
                    "maxBytes" to maxModelBytes,
                    "actualBytes" to modelSize
                )
            )
            return
        }

        Thread {
            Log.i(TAG, "loadModel: native call begin")
            val ok = loadModel(
                path, nCtx, nThreads, nGpuLayers,
                temperature, topK, topP,
                minP, typicalP, topNSigma,
                mirostatType, mirostatTau, mirostatEta,
                repeatPenalty, frequencyPenalty, presencePenalty,
                repeatLastN, minKeep
            )
            Log.i(TAG, "loadModel: native returned $ok")
            Handler(Looper.getMainLooper()).post {
                if (ok) {
                    Log.i(TAG, "loadModel: success")
                    result.success(true)
                } else {
                    Log.e(TAG, "loadModel: failed for $path")
                    result.error("load_failed", "Failed to load model at $path", null)
                }
            }
        }.start()
    }

    private external fun initBackend(): Boolean

    private external fun loadModel(
        modelPath: String,
        contextLength: Int,
        threads: Int,
        gpuLayers: Int,
        temperature: Float,
        topK: Int,
        topP: Float,
        minP: Float,
        typicalP: Float,
        topNSigma: Float,
        mirostatType: Int,
        mirostatTau: Float,
        mirostatEta: Float,
        repeatPenalty: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        repeatLastN: Int,
        minKeep: Int
    ): Boolean

    private external fun generate(prompt: String, maxTokens: Int): String

    private external fun release()

    private external fun updateSampler(
        temperature: Float,
        topK: Int,
        topP: Float,
        minP: Float,
        typicalP: Float,
        topNSigma: Float,
        mirostatType: Int,
        mirostatTau: Float,
        mirostatEta: Float,
        repeatPenalty: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        repeatLastN: Int,
        minKeep: Int
    ): Boolean

    private external fun startGenerate(prompt: String, maxTokens: Int): Boolean

    private external fun nextTokenPiece(): String?

    private external fun cancelGenerate()

    private external fun isStreamActive(): Boolean

    private fun cancelGenerateThreadIfAny() {
        val t = streamingThread
        if (t != null && t.isAlive) {
            try {
                Log.d(TAG, "Joining streaming thread")
                t.join(250)
            } catch (_: InterruptedException) {
            }
        }
        streamingThread = null
    }

    private fun cancelAll() {
        try {
            cancelGenerate()
        } finally {
            cancelGenerateThreadIfAny()
        }
    }
}
