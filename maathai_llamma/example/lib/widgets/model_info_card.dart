import 'package:flutter/material.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';

class ModelInfoCard extends StatelessWidget {
  final ModelInfo model;
  final VoidCallback? onDelete;
  final Widget? trailing;

  const ModelInfoCard({
    super.key,
    required this.model,
    this.onDelete,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing_xs),
                      Text(
                        model.formattedSize,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.errorColor,
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing_md),
            _buildInfoRow(
              context,
              'Status',
              model.isInitialized ? 'Initialized' : 'Not Initialized',
              model.isInitialized ? Icons.check_circle_outline : Icons.pending_outlined,
              model.isInitialized ? AppTheme.primaryColor : Colors.orange,
            ),
            const SizedBox(height: AppTheme.spacing_sm),
            _buildInfoRow(
              context,
              'Context Window',
              '${model.contextWindow} tokens',
              Icons.window_outlined,
              AppTheme.secondaryColor,
            ),
            const SizedBox(height: AppTheme.spacing_sm),
            _buildInfoRow(
              context,
              'Last Modified',
              _formatDate(model.lastModified),
              Icons.access_time,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppTheme.spacing_sm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryTextColor,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryTextColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
