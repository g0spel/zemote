import 'dart:collection';

import 'package:flutter/foundation.dart';

/// One protocol log entry. Lines prefixed with `[诊断]` are human-readable
/// failure explanations (actionable causes, suspected protocol drift); the
/// log page highlights them so they stand out among raw protocol frames.
class LogEntry {
  final DateTime time;
  final String message;

  const LogEntry(this.time, this.message);

  bool get isDiagnostic => message.startsWith('[诊断]');

  /// `[HH:mm:ss.SSS] message` — used for copy / export.
  String get plain =>
      '[${time.hour.toString().padLeft(2, '0')}'
      ':${time.minute.toString().padLeft(2, '0')}'
      ':${time.second.toString().padLeft(2, '0')}'
      '.${time.millisecond.toString().padLeft(3, '0')}] $message';
}

/// Global in-memory protocol log.
class LogStore extends ChangeNotifier {
  static final LogStore instance = LogStore._();

  LogStore._();

  static const maxEntries = 2000;

  final ListQueue<LogEntry> _entries = ListQueue();

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void add(String line) {
    _entries.addLast(LogEntry(DateTime.now(), line));
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

void log(String line) => LogStore.instance.add(line);
