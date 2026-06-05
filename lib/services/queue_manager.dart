import 'dart:async';
import 'dart:collection';
import 'ollama_service.dart';

class QueueTask {
  final String id;
  final String baseUrl;
  final String model;
  final List<Map<String, String>> messages;
  final StreamController<String> controller = StreamController<String>.broadcast();
  final DateTime queuedAt;

  QueueTask({
    required this.id,
    required this.baseUrl,
    required this.model,
    required this.messages,
  }) : queuedAt = DateTime.now();
}

class QueueStatus {
  final String? activeTaskId;
  final int queueLength;
  final bool isProcessing;

  QueueStatus({
    required this.activeTaskId,
    required this.queueLength,
    required this.isProcessing,
  });
}

class QueueManager {
  static final QueueManager _instance = QueueManager._internal();
  factory QueueManager() => _instance;
  QueueManager._internal();

  final OllamaService _ollamaService = OllamaService();
  final DoubleLinkedQueue<QueueTask> _queue = DoubleLinkedQueue<QueueTask>();
  bool _isProcessing = false;
  QueueTask? _activeTask;
  StreamSubscription<String>? _activeSubscription;

  // Stream of queue status updates (e.g. length changes, current active task)
  final StreamController<QueueStatus> _statusController = StreamController<QueueStatus>.broadcast();
  Stream<QueueStatus> get statusStream => _statusController.stream;

  QueueTask? get activeTask => _activeTask;
  int get queueLength => _queue.length;
  bool get isProcessing => _isProcessing;

  /// Enqueues a new chat task. Returns a Stream that will yield tokens
  /// when the task gets executed.
  Stream<String> enqueueChat({
    required String id,
    required String baseUrl,
    required String model,
    required List<Map<String, String>> messages,
  }) {
    final task = QueueTask(
      id: id,
      baseUrl: baseUrl,
      model: model,
      messages: messages,
    );

    _queue.add(task);
    _notifyStatus();

    // Trigger queue processing asynchronously outside the current stack frame
    scheduleMicrotask(() => _processNext());

    return task.controller.stream;
  }

  /// Cancels a task by its unique ID. If it is already running, cancels the
  /// active HTTP subscription. Otherwise, removes it from the pending queue.
  void cancelTask(String id) {
    if (_activeTask?.id == id) {
      _activeSubscription?.cancel();
      _activeTask?.controller.add('\n[Inference Cancelled]');
      _activeTask?.controller.close();
      _activeTask = null;
      _isProcessing = false;
      _notifyStatus();
      scheduleMicrotask(() => _processNext());
    } else {
      _queue.removeWhere((task) {
        if (task.id == id) {
          task.controller.add('\n[Request Cancelled In Queue]');
          task.controller.close();
          return true;
        }
        return false;
      });
      _notifyStatus();
    }
  }

  /// Processes the next task in the queue sequentially.
  Future<void> _processNext() async {
    if (_isProcessing) return;
    if (_queue.isEmpty) {
      _activeTask = null;
      _isProcessing = false;
      _notifyStatus();
      return;
    }

    _isProcessing = true;
    final task = _queue.removeFirst();
    _activeTask = task;
    _notifyStatus();

    try {
      final chatStream = _ollamaService.streamChat(
        baseUrl: task.baseUrl,
        model: task.model,
        messages: task.messages,
      );

      final completer = Completer<void>();

      _activeSubscription = chatStream.listen(
        (chunk) {
          if (!task.controller.isClosed) {
            task.controller.add(chunk);
          }
        },
        onError: (error) {
          if (!task.controller.isClosed) {
            task.controller.addError(error);
          }
        },
        onDone: () {
          completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      if (!task.controller.isClosed) {
        task.controller.addError('Sequential Queue Error: $e');
      }
    } finally {
      if (!task.controller.isClosed) {
        await task.controller.close();
      }
      _activeSubscription = null;
      _activeTask = null;
      _isProcessing = false;
      _notifyStatus();
      
      // Chain to next task
      _processNext();
    }
  }

  void _notifyStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(QueueStatus(
        activeTaskId: _activeTask?.id,
        queueLength: _queue.length,
        isProcessing: _isProcessing,
      ));
    }
  }

  /// Closes stream controllers and releases listeners.
  void dispose() {
    _statusController.close();
    _activeSubscription?.cancel();
    for (var task in _queue) {
      task.controller.close();
    }
    _queue.clear();
  }
}
