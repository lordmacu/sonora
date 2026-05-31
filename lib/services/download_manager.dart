import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'youtube_service.dart';

enum DownloadStatus { queued, downloading, done, error }

class DownloadTask {
  final String videoId;
  final String title;
  final String author;
  final String thumbnailUrl;
  DownloadStatus status;
  double progress;
  String? error;

  DownloadTask({
    required this.videoId,
    required this.title,
    required this.author,
    this.thumbnailUrl = '',
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.error,
  });
}

/// Cola de descargas con concurrencia limitada. Equivalente a DownloadService.kt.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this._youtube, {this.maxConcurrent = 3});

  final YoutubeService _youtube;
  final int maxConcurrent;

  final Map<String, DownloadTask> _tasks = {};
  final Queue<String> _pending = Queue();
  final Set<String> _active = {};
  final Map<String, StreamSubscription> _subs = {};

  UnmodifiableMapView<String, DownloadTask> get tasks => UnmodifiableMapView(_tasks);

  DownloadTask? taskFor(String videoId) => _tasks[videoId];

  bool isDownloading(String videoId) {
    final t = _tasks[videoId];
    return t != null &&
        (t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued);
  }

  void enqueue(String videoId, String title, String author, {String thumbnailUrl = ''}) {
    if (_tasks.containsKey(videoId) &&
        _tasks[videoId]!.status != DownloadStatus.error) {
      return;
    }
    _tasks[videoId] = DownloadTask(
      videoId: videoId,
      title: title,
      author: author,
      thumbnailUrl: thumbnailUrl,
    );
    _pending.add(videoId);
    notifyListeners();
    _pump();
  }

  void cancel(String videoId) {
    _subs.remove(videoId)?.cancel();
    _active.remove(videoId);
    _pending.remove(videoId);
    final t = _tasks[videoId];
    if (t != null && t.status != DownloadStatus.done) {
      t.status = DownloadStatus.error;
      t.error = 'Cancelado';
    }
    notifyListeners();
    _pump();
  }

  void _pump() {
    while (_active.length < maxConcurrent && _pending.isNotEmpty) {
      final videoId = _pending.removeFirst();
      final task = _tasks[videoId];
      if (task == null) continue;
      _active.add(videoId);
      task.status = DownloadStatus.downloading;
      notifyListeners();

      _subs[videoId] = _youtube
          .downloadAudio(videoId, task.title, task.author,
              thumbnailUrl: task.thumbnailUrl)
          .listen(
        (p) {
          task.progress = p.progress;
          notifyListeners();
        },
        onError: (e) {
          task.status = DownloadStatus.error;
          task.error = e.toString();
          _finish(videoId);
        },
        onDone: () {
          if (task.status != DownloadStatus.error) {
            task.status = DownloadStatus.done;
            task.progress = 1;
          }
          _finish(videoId);
        },
      );
    }
  }

  void _finish(String videoId) {
    _subs.remove(videoId)?.cancel();
    _active.remove(videoId);
    notifyListeners();
    _pump();
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }
}
