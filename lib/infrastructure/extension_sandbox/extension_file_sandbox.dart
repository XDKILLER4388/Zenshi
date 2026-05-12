import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/failures.dart';

/// Restricts extension file access to a designated cache directory.
///
/// Each extension gets an isolated subdirectory under the application cache
/// directory. Any attempt to read or write a path outside that directory is
/// rejected with an [ExtensionFailure], preventing path-traversal attacks.
class ExtensionFileSandbox {
  final String extensionId;
  String? _sandboxPath;

  ExtensionFileSandbox(this.extensionId);

  /// Returns the sandbox root directory for this extension.
  ///
  /// Creates the directory if it does not already exist.
  Future<Directory> getSandboxDirectory() async {
    if (_sandboxPath != null) {
      return Directory(_sandboxPath!);
    }
    final cacheDir = await getApplicationCacheDirectory();
    final sandboxDir =
        Directory('${cacheDir.path}/extensions/$extensionId');
    await sandboxDir.create(recursive: true);
    _sandboxPath = sandboxDir.path;
    return sandboxDir;
  }

  /// Validates that [path] is within the sandbox directory.
  ///
  /// Throws [ExtensionFailure] if the resolved absolute path escapes the
  /// sandbox root (e.g. via `../` traversal).
  Future<void> validatePath(String path) async {
    final sandbox = await getSandboxDirectory();
    final normalizedPath = File(path).absolute.path;
    final normalizedSandbox = sandbox.absolute.path;
    if (!normalizedPath.startsWith(normalizedSandbox)) {
      throw ExtensionFailure(
        message: 'Extension "$extensionId" attempted to access path outside '
            'sandbox: $path',
        extensionId: extensionId,
      );
    }
  }

  /// Reads a file at [relativePath] within the sandbox.
  ///
  /// Throws [ExtensionFailure] if the path escapes the sandbox or the file
  /// does not exist.
  Future<String> readFile(String relativePath) async {
    final sandbox = await getSandboxDirectory();
    final file = File('${sandbox.path}/$relativePath');
    await validatePath(file.path);
    if (!await file.exists()) {
      throw ExtensionFailure(
        message: 'File not found in extension sandbox: $relativePath',
        extensionId: extensionId,
      );
    }
    return file.readAsString();
  }

  /// Writes [content] to a file at [relativePath] within the sandbox.
  ///
  /// Creates intermediate directories as needed.
  /// Throws [ExtensionFailure] if the path escapes the sandbox.
  Future<void> writeFile(String relativePath, String content) async {
    final sandbox = await getSandboxDirectory();
    final file = File('${sandbox.path}/$relativePath');
    await validatePath(file.path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Deletes all files in the sandbox.
  ///
  /// Called when an extension is uninstalled. Resets the cached sandbox path
  /// so a fresh directory is created if the extension is reinstalled.
  Future<void> clearSandbox() async {
    final sandbox = await getSandboxDirectory();
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
    _sandboxPath = null;
  }
}
