import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

class ModelInfo {
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime lastModified;
  final int contextWindow;
  final Map<String, dynamic> metadata;

  ModelInfo({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.lastModified,
    this.contextWindow = 4096,
    this.metadata = const {},
  });

  String get formattedSize {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

class ModelService {
  static const int maxModelSizeBytes = 1024 * 1024 * 1024; // 1 GB limit
  
  Future<Directory> get _modelsDirectory async {
    final appDir = await getApplicationSupportDirectory();
    final modelsDir = Directory(path.join(appDir.path, 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  Future<List<ModelInfo>> getAvailableModels() async {
    final models = <ModelInfo>[];
    final modelsDir = await _modelsDirectory;
    
    try {
      await for (final entity in modelsDir.list()) {
        if (entity is File && path.extension(entity.path).toLowerCase() == '.gguf') {
          final stat = await entity.stat();
          models.add(ModelInfo(
            name: path.basename(entity.path),
            path: entity.path,
            sizeBytes: stat.size,
            lastModified: stat.modified,
          ));
        }
      }
    } catch (e) {
      Logger.error('Failed to list models: $e');
      rethrow;
    }
    
    return models;
  }

  Future<ModelInfo?> importModel({
    void Function(int progress, int total)? onProgress,
  }) async {
    try {
      // Note: some OEMs don't support custom extension filtering; use any and validate ourselves
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        Logger.info('Model selection cancelled');
        return null;
      }

      final selected = result.files.single;
      final sourcePath = selected.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        throw Exception('Selected file has no filesystem path');
      }

      final ext = path.extension(sourcePath).toLowerCase();
      if (ext != '.gguf') {
        throw Exception('Unsupported file type: $ext. Please select a .gguf model file.');
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Selected file does not exist');
      }

      final fileSize = await sourceFile.length();
      if (fileSize > maxModelSizeBytes) {
        throw Exception(
          'Model size (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB) '
          'exceeds maximum allowed size (${(maxModelSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB)',
        );
      }

      final modelsDir = await _modelsDirectory;
      final destPath = path.join(modelsDir.path, path.basename(sourcePath));
      final destFile = File(destPath);

      // Copy file in chunks to show progress
      final sourceStream = sourceFile.openRead();
      final sink = destFile.openWrite();
      int copied = 0;

      try {
        await for (final chunk in sourceStream) {
          copied += chunk.length;
          sink.add(chunk);
          onProgress?.call(copied, fileSize);
        }
      } finally {
        await sink.close();
      }

      final modelInfo = ModelInfo(
        name: path.basename(destPath),
        path: destPath,
        sizeBytes: fileSize,
        lastModified: DateTime.now(),
      );

      Logger.success('Model imported successfully: ${modelInfo.name}');
      return modelInfo;
    } catch (e) {
      Logger.error('Failed to import model: $e');
      rethrow;
    }
  }

  Future<void> deleteModel(ModelInfo model) async {
    try {
      final file = File(model.path);
      if (await file.exists()) {
        await file.delete();
        Logger.success('Model deleted successfully: ${model.name}');
      } else {
        Logger.warning('Model file not found: ${model.path}');
      }
    } catch (e) {
      Logger.error('Failed to delete model: $e');
      rethrow;
    }
  }
}
