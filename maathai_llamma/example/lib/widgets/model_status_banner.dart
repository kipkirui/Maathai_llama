import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/model_controller.dart';
import '../theme/app_theme.dart';

class ModelStatusBanner extends StatelessWidget {
  const ModelStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelController>(
      builder: (context, c, _) {
        final backendText = c.backendReady ? 'Backend: Ready' : 'Backend: Not initialized';
        final backendColor = c.backendReady ? Colors.green : Colors.orange;
        final modelText = c.modelLoaded && c.activeModel != null
            ? 'Model: ${c.activeModel!.name}  •  ctx ${c.contextLength}  •  threads ${c.threads}  •  GPU ${c.gpuLayers}'
            : 'Model: Not loaded';
        final modelColor = c.modelLoaded ? AppTheme.primaryTextColor : AppTheme.secondaryTextColor;

        return Card(
          margin: const EdgeInsets.all(AppTheme.spacing_md),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.power_settings_new, size: 16, color: backendColor),
                    const SizedBox(width: AppTheme.spacing_xs),
                    Text(
                      backendText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: backendColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing_sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.memory, size: 16, color: AppTheme.secondaryTextColor),
                    const SizedBox(width: AppTheme.spacing_xs),
                    Expanded(
                      child: Text(
                        modelText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: modelColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


