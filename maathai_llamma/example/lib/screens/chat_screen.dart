import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/model_service.dart';
import '../utils/logger.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/model_status_banner.dart';
import '../widgets/typing_indicator.dart';
import 'package:provider/provider.dart';
import '../state/model_controller.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final String? error;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isGenerating = false;
  bool _showThinking = true;
  String _status = 'Initializing...';
  ModelInfo? _activeModel;
  bool _captureThinking = true; // toggle to capture <think> blocks

  // simple thinking capture state
  bool _inThink = false;
  final StringBuffer _thinkBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    Logger.addListener(_onLogEntry);
  }

  @override
  void dispose() {
    Logger.removeListener(_onLogEntry);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogEntry(LogEntry entry) {
    if (!mounted) return;
    
    if (entry.level == LogLevel.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(entry.message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isGenerating) return;

    setState(() {
      _messages.add(ChatMessage(
        role: 'User',
        content: message,
      ));
      _isGenerating = true;
      _status = 'Generating response...';
    });

    _scrollToBottom();

    try {
      Logger.info('SendMessage begin', data: {
        'prompt': message,
        'modelLoaded': _activeModel != null,
      });
      Logger.info('Sending message to model', data: {
        'message': message,
        'model': _activeModel?.name,
      });

      final controller = context.read<ModelController>();
      if (!controller.modelLoaded) {
        throw Exception('Model not loaded');
      }
      // Stream tokens
      String buffer = '';
      await for (final chunk in controller.generateStream(message, maxTokens: 128)) {
        String incoming = chunk;
        if (_captureThinking) {
          // capture <think> ... </think> and do not show in chat when enabled
          if (!_inThink) {
            final openIdx = incoming.indexOf('<think>');
            if (openIdx != -1) {
              _inThink = true;
              final before = incoming.substring(0, openIdx);
              final after = incoming.substring(openIdx + 7);
              incoming = before;
              _thinkBuffer.clear();
              _thinkBuffer.write(after);
            }
          } else {
            // already inside think
            final closeIdx = incoming.indexOf('</think>');
            if (closeIdx != -1) {
              _thinkBuffer.write(incoming.substring(0, closeIdx));
              // close block, drop content
              _inThink = false;
              incoming = incoming.substring(closeIdx + 8);
            } else {
              _thinkBuffer.write(incoming);
              incoming = '';
            }
          }
        }

        if (incoming.isEmpty) {
          // keep UI typing indicator but do not append
          if (mounted) setState(() {});
          continue;
        }

        buffer += chunk;
        if (!mounted) break;
        setState(() {
          // on first chunk, append placeholder assistant message
          if (_messages.isEmpty || _messages.last.role != 'Assistant') {
            _messages.add(ChatMessage(role: 'Assistant', content: incoming));
          } else {
            _messages[_messages.length - 1] = ChatMessage(role: 'Assistant', content: (_messages.last.content + incoming));
          }
        });
        _scrollToBottom();
      }
      Logger.success('Streaming completed');
      setState(() {
        _isGenerating = false;
        _status = 'Ready';
      });

      Logger.success('Generated response successfully');
    } catch (e, st) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'Assistant',
          content: 'Failed to generate response',
          error: e.toString(),
        ));
        _isGenerating = false;
        _status = 'Error: $e';
      });

      Logger.error('Failed to generate response', data: {'error': e.toString(), 'stack': st.toString()});
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() => _messages.clear());
        Logger.info('Chat history cleared');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat'),
            Consumer<ModelController>(
              builder: (context, c, _) => Text(
                c.backendReady
                    ? (c.modelLoaded ? 'Ready' : 'Backend ready - no model loaded')
                    : 'Backend not initialized',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.backendReady ? AppTheme.secondaryTextColor : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ModelController>(
            builder: (context, c, _) => IconButton(
              icon: const Icon(Icons.power_settings_new),
              tooltip: 'Initialize backend',
              onPressed: c.backendReady
                  ? null
                  : () async {
                      final ok = await c.initializeBackend();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Backend initialized' : 'Backend init failed'),
                            backgroundColor: ok ? Colors.green : AppTheme.errorColor,
                          ),
                        );
                      }
                    },
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
              tooltip: 'Clear Chat',
            ),
          Consumer<ModelController>(
            builder: (context, controller, _) => IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Cancel generation',
              onPressed: _isGenerating ? () async {
                await controller.cancel();
              } : null,
            ),
          ),
        ],
      ),
      body: Consumer<ModelController>(
        builder: (context, controller, _) {
          _activeModel = controller.activeModel;
          // sync UI options from controller
          _showThinking = controller.showThinkingIndicator;
          _captureThinking = controller.captureThinking;
          final ready = controller.modelLoaded;
          return Column(
        children: [
          const ModelStatusBanner(),
          if (_activeModel == null)
            Container(
              color: AppTheme.surfaceColor,
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: AppTheme.spacing_sm),
                  Expanded(
                    child: Text(
                      'No model loaded. Please load a model from the Models tab to start chatting.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppTheme.spacing_md),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacing_sm),
                        Text(
                          'Start a conversation by sending a message',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
                    itemCount: _messages.length + (_isGenerating && _showThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isGenerating && _showThinking && index == _messages.length) {
                        return const TypingIndicator();
                      }
                      final message = _messages[index];
                      final showTimestamp = index == 0 ||
                          message.timestamp.difference(_messages[index - 1].timestamp).inMinutes > 5;
                      
                      return Column(
                        children: [
                          if (showTimestamp)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing_md,
                              ),
                              child: Text(
                                DateFormat.yMMMd().add_jm().format(message.timestamp),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                            ),
                          ChatMessageWidget(message: message),
                        ],
                      );
                    },
                  ),
          ),
          ChatInput(
            onSendMessage: _sendMessage,
            enabled: ready && !_isGenerating,
            isGenerating: _isGenerating,
          ),
        ],
      );
        },
      ),
    );
  }
}
