import 'dart:io';
import 'package:flutter/material.dart';
// switched to file_picker to avoid loading file bytes into memory
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/model_info_card.dart';
import '../widgets/model_status_banner.dart';
import '../services/model_service.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';
import '../state/model_controller.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final ModelService _modelService = ModelService();
  List<ModelInfo> _availableModels = [];
  bool _isLoading = false;
  double? _importProgress; // 0.0 - 1.0

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await _modelService.getAvailableModels();
      setState(() => _availableModels = models);
    } catch (e) {
      Logger.error('Failed to load models: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load models: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importModel() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final model = await _modelService.importModel(
        onProgress: (progress, total) {
          final pct = total > 0 ? progress / total : 0.0;
          setState(() => _importProgress = pct);
          Logger.info('Importing model: ${(pct * 100).toStringAsFixed(1)}%');
        },
      );
      
      if (model != null) {
        setState(() => _availableModels.add(model));
        Logger.success('Model imported successfully: ${model.name}');
      }
    } catch (e) {
      Logger.error('Failed to import model: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import model: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _importProgress = null;
      });
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
      setState(() => _isLoading = true);
      try {
        await _modelService.deleteModel(model);
        setState(() {
          _availableModels.removeWhere((m) => m.path == model.path);
        });
        Logger.success('Model deleted successfully: ${model.name}');
      } catch (e) {
        Logger.error('Failed to delete model: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete model: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _isLoading ? null : _loadAvailableModels,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_importProgress != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_md),
                      child: LinearProgressIndicator(value: _importProgress!.clamp(0.0, 1.0)),
                    )
                  else
                    const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spacing_md),
                  Text(
                    _importProgress != null
                        ? 'Importing ${(100 * _importProgress!).toStringAsFixed(1)}%'
                        : 'Loading...'
                  ),
                ],
              ),
            )
          : _availableModels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.memory_outlined,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
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
                )
              : Column(
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
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _importModel,
        icon: const Icon(Icons.add),
        label: const Text('Import Model'),
      ),
    );
  }
}
