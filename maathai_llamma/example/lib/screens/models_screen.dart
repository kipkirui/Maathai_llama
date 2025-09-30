import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';
import '../state/model_controller.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../widgets/model_info_card.dart';
import '../widgets/model_status_banner.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final ModelService _modelService = ModelService();
  List<ModelInfo> _availableModels = [];
  bool _isLoadingModels = false;
  bool _isImporting = false;
  double? _importProgress; // 0.0 - 1.0

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    setState(() => _isLoadingModels = true);
    try {
      final models = await _modelService.getAvailableModels();
      if (mounted) {
        setState(() => _availableModels = models);
      }
    } catch (e) {
      Logger.error('Failed to load models: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load models: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingModels = false);
      }
    }
  }

  Future<void> _importModel() async {
    if (_isLoadingModels || _isImporting) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0;
    });
    try {
      final model = await _modelService.importModel(
        onProgress: (progress, total) {
          final pct = total > 0 ? progress / total : 0.0;
          if (mounted) {
            setState(() => _importProgress = pct);
          }
          Logger.info('Importing model: ${(pct * 100).toStringAsFixed(1)}%');
        },
      );
      
      if (model != null) {
        if (mounted) {
          setState(() => _availableModels.add(model));
        }
        Logger.success('Model imported successfully: ${model.name}');
      }
    } catch (e) {
      Logger.error('Failed to import model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import model: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importProgress = null;
        });
      }
    }
  }

  Future<void> _deleteModel(ModelInfo model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.name}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoadingModels = true);
      try {
        await _modelService.deleteModel(model);
        if (mounted) {
          setState(() {
            _availableModels.removeWhere((m) => m.path == model.path);
          });
        }
        Logger.success('Model deleted successfully: ${model.name}');
      } catch (e) {
        Logger.error('Failed to delete model: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete model: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingModels = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget bodyContent;

    if (_isLoadingModels) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spacing_md),
            Text('Loading...'),
          ],
        ),
      );
    } else if (_availableModels.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Text(
              'No models available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing_sm),
            Text(
              'Import a model to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    } else {
      bodyContent = Column(
        children: [
          const ModelStatusBanner(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              itemCount: _availableModels.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing_md),
              itemBuilder: (context, index) {
                final model = _availableModels[index];
                return Consumer<ModelController>(
                  builder: (context, controller, _) => ModelInfoCard(
                    model: model,
                    backendReady: controller.backendReady,
                    onDelete: () => _deleteModel(model),
                    trailing: controller.activeModel?.path == model.path
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                        : TextButton(
                            onPressed: () async {
                              if (!controller.backendReady) {
                                final ok = await controller.initializeBackend();
                                if (!ok) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Backend init failed')),
                                    );
                                  }
                                  return;
                                }
                              }
                              final ok = await controller.loadModel(model);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to load model')),
                                );
                              } else {
                                Logger.success('Active model set: ${model.name}');
                              }
                            },
                            child: const Text('Load'),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    final progressValue = _importProgress?.clamp(0.0, 1.0);
    final progressLabel = progressValue != null
        ? 'Importing ${(progressValue * 100).toStringAsFixed(1)}%'
        : 'Importing...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Models'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoadingModels || _isImporting) ? null : _loadAvailableModels,
          ),
        ],
      ),
      body: bodyContent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_isLoadingModels || _isImporting) ? null : _importModel,
        icon: const Icon(Icons.add),
        label: const Text('Import Model'),
      ),
      bottomNavigationBar: _isImporting
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing_md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: progressValue),
                    const SizedBox(height: AppTheme.spacing_xs),
                    Text(
                      progressLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
