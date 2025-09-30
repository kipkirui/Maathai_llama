import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  success,
  warning,
  error,
}

class Logger {
  static final List<LogEntry> _logs = [];
  static final List<void Function(LogEntry)> _listeners = [];

  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void addListener(void Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  static void _log(LogLevel level, String message, {dynamic data}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      data: data,
    );
    
    _logs.add(entry);
    
    // Notify listeners
    for (final listener in _listeners) {
      listener(entry);
    }
    
    // Print to console in debug mode
    if (kDebugMode) {
      final emoji = switch (level) {
        LogLevel.debug => '🔍',
        LogLevel.info => 'ℹ️',
        LogLevel.success => '✅',
        LogLevel.warning => '⚠️',
        LogLevel.error => '❌',
      };
      
      print('$emoji [${level.name.toUpperCase()}] $message');
      if (data != null) {
        print('   Data: $data');
      }
    }
  }

  static void debug(String message, {dynamic data}) {
    _log(LogLevel.debug, message, data: data);
  }

  static void info(String message, {dynamic data}) {
    _log(LogLevel.info, message, data: data);
  }

  static void success(String message, {dynamic data}) {
    _log(LogLevel.success, message, data: data);
  }

  static void warning(String message, {dynamic data}) {
    _log(LogLevel.warning, message, data: data);
  }

  static void error(String message, {dynamic data}) {
    _log(LogLevel.error, message, data: data);
  }

  static void clearLogs() {
    _logs.clear();
  }

  static List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  static List<LogEntry> getLogsBetween(DateTime start, DateTime end) {
    return _logs
        .where((log) => log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList();
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic data;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$timeStr] [${level.name.toUpperCase()}] $message';
  }
}
