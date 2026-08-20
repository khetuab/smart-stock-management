import 'dart:convert';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'backup_file_info.dart';

Future<bool> requestBackupPermission() async => true; // the browser handles its own download prompt

Future<BackupFileInfo?> saveBackupJson(String jsonData, {required bool auto}) async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = auto ? 'auto_backup_$timestamp.json' : 'backup_$timestamp.json';
    final bytes = utf8.encode(jsonData);

    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);

    return BackupFileInfo(
      name: filename,
      path: null,
      sizeBytes: bytes.length,
      modifiedDate: DateTime.now(),
    );
  } catch (e) {
    print('Error saving backup file on web: $e');
    return null;
  }
}

Future<void> shareBackupFile(BackupFileInfo file, {required String subject, required String text}) async {
  // saveBackupJson already triggered a real browser download above — there's
  // no separate OS share-sheet equivalent to hand the same file to on web.
}

/// Web has no persistent app directory, so there's nothing to list —
/// restoreBackup() below switches to pickBackupFile() (a file upload)
/// on web instead of showing this (always-empty) internal list.
Future<List<BackupFileInfo>> listBackupFiles() async => [];

Future<String> readBackupFileContents(BackupFileInfo file) async => '';

Future<bool> deleteBackupFile(BackupFileInfo file) async => false;

Future<String> formatBackupSize(BackupFileInfo file) async {
  final size = file.sizeBytes;
  if (size > 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (size > 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '$size B';
}

Future<PickedBackup?> pickBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.first;
  if (picked.bytes == null) return null;

  final content = utf8.decode(picked.bytes!);
  return PickedBackup(name: picked.name, jsonContent: content);
}