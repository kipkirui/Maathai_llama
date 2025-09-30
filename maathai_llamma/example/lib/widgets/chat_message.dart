import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';
import '../theme/app_theme.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'User';
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
          margin: EdgeInsets.only(
            bottom: AppTheme.spacing_sm,
            left: isUser ? AppTheme.spacing_xl : 0,
            right: isUser ? 0 : AppTheme.spacing_xl,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.error != null)
                  Container(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.errorColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: AppTheme.spacing_xs),
                        Expanded(
                          child: Text(
                            message.error!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SelectableText(
                  message.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isUser
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
