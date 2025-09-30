import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';
import '../state/model_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<LogEntry> _logs = [];
  bool _showDebugLogs = false;

  @override
  void initState() {
    super.initState();
    _updateLogs();
    Logger.addListener(_onLogEntry);
  }

  @override
  void dispose() {
    Logger.removeListener(_onLogEntry);
    super.dispose();
  }

  void _onLogEntry(LogEntry entry) {
    if (!mounted) return;
    setState(() => _updateLogs());
  }

  void _updateLogs() {
    setState(() {
      _logs.clear();
      _logs.addAll(
        Logger.logs.where((log) => _showDebugLogs || log.level != LogLevel.debug),
      );
    });
  }

  void _clearLogs() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
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
        Logger.clearLogs();
        _updateLogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearLogs,
              tooltip: 'Clear Logs',
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacing_sm),
                SwitchListTile(
                  title: const Text('Show Debug Logs'),
                  value: _showDebugLogs,
                  onChanged: (value) {
                    setState(() {
                      _showDebugLogs = value;
                      _updateLogs();
                    });
                  },
                ),
              ],
            ),
          ),
          Consumer<ModelController>(
            builder: (context, controller, _) {
              return Padding(
                padding: const EdgeInsets.all(AppTheme.spacing_md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Performance Settings', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppTheme.spacing_sm),
                    _IntSliderRow(
                      label: 'Threads',
                      value: controller.threads == 0 ? 4 : controller.threads,
                      min: 1,
                      max: 8,
                      onChanged: (v) => controller.setThreads(v),
                    ),
                    _IntSliderRow(
                      label: 'GPU Layers',
                      value: controller.gpuLayers,
                      min: 0,
                      max: 32,
                      onChanged: (v) => controller.setGpuLayers(v),
                    ),
                    _IntSliderRow(
                      label: 'Context Length',
                      value: controller.contextLength,
                      min: 256,
                      max: 8192,
                      onChanged: (v) => controller.setContextLength(v),
                    ),
                    const SizedBox(height: AppTheme.spacing_sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: controller.activeModel == null
                            ? null
                            : () async {
                                final model = controller.activeModel!;
                                final ok = await controller.loadModel(
                                  model,
                                  contextLength: controller.contextLength,
                                  threads: controller.threads,
                                  gpuLayers: controller.gpuLayers,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Model reloaded with new settings' : 'Reload failed'),
                                      backgroundColor: ok ? Colors.green : AppTheme.errorColor,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reload Model with New Settings'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing_md),
                    Text('Thinking Settings', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppTheme.spacing_sm),
                    SwitchListTile(
                      title: const Text('Show typing indicator while generating'),
                      value: controller.showThinkingIndicator,
                      onChanged: (v) => controller.setShowThinkingIndicator(v),
                    ),
                    SwitchListTile(
                      title: const Text('Hide <think> content from chat'),
                      value: controller.captureThinking,
                      onChanged: (v) => controller.setCaptureThinking(v),
                    ),
                    const SizedBox(height: AppTheme.spacing_md),
                    Text('Sampler Settings', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppTheme.spacing_sm),
                    _SliderRow(
                      label: 'Temperature',
                      value: controller.temperature,
                      min: 0.0,
                      max: 2.0,
                      onChanged: (v) => controller.updateSamplerParams(temperature: v),
                    ),
                    _IntSliderRow(
                      label: 'TopK',
                      value: controller.topK,
                      min: 0,
                      max: 200,
                      onChanged: (v) => controller.updateSamplerParams(topK: v),
                    ),
                    _SliderRow(
                      label: 'TopP',
                      value: controller.topP,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => controller.updateSamplerParams(topP: v),
                    ),
                    _SliderRow(
                      label: 'MinP',
                      value: controller.minP ?? 0.0,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => controller.updateSamplerParams(minP: v > 0 ? v : null),
                    ),
                    _SliderRow(
                      label: 'TypicalP',
                      value: controller.typicalP ?? 0.0,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => controller.updateSamplerParams(typicalP: v > 0 ? v : null),
                    ),
                    _SliderRow(
                      label: 'TopNSigma',
                      value: controller.topNSigma ?? 0.0,
                      min: 0.0,
                      max: 10.0,
                      onChanged: (v) => controller.updateSamplerParams(topNSigma: v > 0 ? v : null),
                    ),
                    _IntSliderRow(
                      label: 'Repeat last N',
                      value: controller.repeatLastN ?? 64,
                      min: 0,
                      max: 512,
                      onChanged: (v) => controller.updateSamplerParams(repeatLastN: v > 0 ? v : null),
                    ),
                    _SliderRow(
                      label: 'Repeat penalty',
                      value: controller.repeatPenalty ?? 1.0,
                      min: 0.8,
                      max: 2.0,
                      onChanged: (v) => controller.updateSamplerParams(repeatPenalty: v),
                    ),
                    _SliderRow(
                      label: 'Presence penalty',
                      value: controller.presencePenalty ?? 0.0,
                      min: 0.0,
                      max: 2.0,
                      onChanged: (v) => controller.updateSamplerParams(presencePenalty: v),
                    ),
                    _SliderRow(
                      label: 'Frequency penalty',
                      value: controller.frequencyPenalty ?? 0.0,
                      min: 0.0,
                      max: 2.0,
                      onChanged: (v) => controller.updateSamplerParams(frequencyPenalty: v),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            child: Text('Logs', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 32,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppTheme.spacing_sm),
                  Text(
                    'No logs available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing_sm),
                  Text(
                    'System logs will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final color = switch (log.level) {
                  LogLevel.debug => Colors.grey,
                  LogLevel.info => Colors.blue,
                  LogLevel.success => Colors.green,
                  LogLevel.warning => Colors.orange,
                  LogLevel.error => AppTheme.errorColor,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        switch (log.level) {
                          LogLevel.debug => Icons.bug_report,
                          LogLevel.info => Icons.info,
                          LogLevel.success => Icons.check_circle,
                          LogLevel.warning => Icons.warning,
                          LogLevel.error => Icons.error,
                        },
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: AppTheme.spacing_sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: color,
                              ),
                            ),
                            if (log.data != null)
                              Text(
                                log.data.toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(value.toStringAsFixed(2), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _IntSliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _IntSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text('$value', textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
