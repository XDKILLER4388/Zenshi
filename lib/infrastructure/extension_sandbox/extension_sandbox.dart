import 'dart:isolate';
import '../../core/errors/failures.dart';
import 'extension_manifest.dart';
import 'extension_http_proxy.dart';

/// Message types for isolate communication.
enum SandboxMessageType { search, chapterList, pageList, imageUrl, ping }

/// A request sent from the main isolate to the extension isolate.
class SandboxRequest {
  final String requestId;
  final SandboxMessageType type;
  final Map<String, dynamic> params;
  final SendPort replyPort;

  const SandboxRequest({
    required this.requestId,
    required this.type,
    required this.params,
    required this.replyPort,
  });
}

/// A response returned from the extension isolate to the main isolate.
class SandboxResponse {
  final String requestId;
  final bool success;
  final dynamic data;
  final String? error;

  const SandboxResponse({
    required this.requestId,
    required this.success,
    this.data,
    this.error,
  });
}

/// Manages a per-extension Dart Isolate with sandboxed network access.
///
/// Each installed extension runs in its own isolate. Communication is
/// performed via [SendPort]/[ReceivePort] message passing. Network access
/// inside the isolate is routed through [ExtensionHttpProxy] which enforces
/// the domain whitelist declared in the extension's [ExtensionManifest].
class ExtensionSandbox {
  final ExtensionManifest manifest;

  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();
  bool _isRunning = false;

  ExtensionSandbox(this.manifest);

  /// Whether the extension isolate is currently running.
  bool get isRunning => _isRunning;

  /// Spawns the extension isolate.
  ///
  /// Throws [ExtensionFailure] if the isolate cannot be started.
  Future<void> start() async {
    try {
      _isolate = await Isolate.spawn(
        _extensionIsolateEntryPoint,
        _IsolateInitParams(
          sendPort: _receivePort.sendPort,
          manifest: manifest,
        ),
        errorsAreFatal: false,
        debugName: 'ext_${manifest.id}',
      );
      // Wait for the isolate to send back its SendPort.
      _sendPort = await _receivePort.first as SendPort;
      _isRunning = true;
    } on IsolateSpawnException catch (e) {
      throw ExtensionFailure(
        message: 'Failed to start extension ${manifest.id}: ${e.message}',
        extensionId: manifest.id,
        cause: e,
      );
    }
  }

  /// Sends a request to the extension isolate and waits for a response.
  ///
  /// Throws [ExtensionFailure] if the isolate is not running.
  Future<SandboxResponse> sendRequest(SandboxRequest request) async {
    if (!_isRunning || _sendPort == null) {
      throw ExtensionFailure(
        message: 'Extension ${manifest.id} is not running',
        extensionId: manifest.id,
      );
    }
    final replyPort = ReceivePort();
    _sendPort!.send(SandboxRequest(
      requestId: request.requestId,
      type: request.type,
      params: request.params,
      replyPort: replyPort.sendPort,
    ));
    final response = await replyPort.first as SandboxResponse;
    replyPort.close();
    return response;
  }

  /// Stops the extension isolate and releases all resources.
  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _isRunning = false;
  }
}

// ── Isolate internals ─────────────────────────────────────────────────────────

class _IsolateInitParams {
  final SendPort sendPort;
  final ExtensionManifest manifest;

  const _IsolateInitParams({
    required this.sendPort,
    required this.manifest,
  });
}

/// Entry point for the extension isolate.
///
/// This function runs in a separate Dart isolate with restricted capabilities.
/// All HTTP calls are routed through [ExtensionHttpProxy].
void _extensionIsolateEntryPoint(_IsolateInitParams params) {
  final receivePort = ReceivePort();
  // Send our SendPort back to the main isolate so it can talk to us.
  params.sendPort.send(receivePort.sendPort);

  final proxy =
      ExtensionHttpProxy(allowedDomains: params.manifest.allowedDomains);

  receivePort.listen((message) {
    if (message is SandboxRequest) {
      _handleRequest(message, proxy);
    }
  });
}

void _handleRequest(SandboxRequest request, ExtensionHttpProxy proxy) async {
  try {
    final result = await _dispatchRequest(request, proxy);
    request.replyPort.send(SandboxResponse(
      requestId: request.requestId,
      success: true,
      data: result,
    ));
  } catch (e) {
    request.replyPort.send(SandboxResponse(
      requestId: request.requestId,
      success: false,
      error: e.toString(),
    ));
  }
}

Future<dynamic> _dispatchRequest(
  SandboxRequest request,
  ExtensionHttpProxy proxy,
) async {
  switch (request.type) {
    case SandboxMessageType.ping:
      return 'pong';
    case SandboxMessageType.search:
    case SandboxMessageType.chapterList:
    case SandboxMessageType.pageList:
    case SandboxMessageType.imageUrl:
      // Placeholder — real extension dispatch is implemented when extensions
      // are loaded from their compiled Dart kernel snapshots.
      return <String, dynamic>{};
  }
}
