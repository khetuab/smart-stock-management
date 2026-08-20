import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'backup_file_info.dart';

const String _backupFolder = 'SmartStockBackups';

Future<bool> requestBackupPermission() async {
  if (Platform.isAndroid || Platform.isIOS) {
    if (await Permission.storage.isGranted) return true;
    final status = await Permission.storage.request();
    return status.isGranted || Platform.isAndroid;
  }
  return true;
}

Future<Directory> _backupDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  final directory = Directory('${appDir.path}/$_backupFolder');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

Future<BackupFileInfo?> saveBackupJson(String jsonData, {required bool auto}) async {
  try {
    final directory = await _backupDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = auto ? 'auto_backup_$timestamp.json' : 'backup_$timestamp.json';
    final file = File('${directory.path}/$filename');
    await file.writeAsString(jsonData);
    final stat = await file.stat();

    return BackupFileInfo(
      name: filename,
      path: file.path,
      sizeBytes: stat.size,
      modifiedDate: stat.modified,
    );
  } catch (e) {
    print('Error saving backup file: $e');
    return null;
  }
}

Future<void> shareBackupFile(BackupFileInfo file, {required String subject, required String text}) async {
  if (file.path == null) return;
  await Share.shareXFiles(
    [XFile(file.path!, mimeType: 'application/json')],
    subject: subject,
    text: text,
  );
}

Future<List<BackupFileInfo>> listBackupFiles() async {
  try {
    final directory = await _backupDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    final infos = <BackupFileInfo>[];
    for (final f in files) {
      final stat = await f.stat();
      infos.add(BackupFileInfo(
        name: f.path.split(Platform.pathSeparator).last,
        path: f.path,
        sizeBytes: stat.size,
        modifiedDate: stat.modified,
      ));
    }
    infos.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return infos;
  } catch (e) {
    print('Error listing backup files: $e');
    return [];
  }
}

Future<String> readBackupFileContents(BackupFileInfo file) async {
  if (file.path == null) return '';
  return File(file.path!).readAsString();
}

Future<bool> deleteBackupFile(BackupFileInfo file) async {
  try {
    if (file.path == null) return false;
    final f = File(file.path!);
    if (await f.exists()) {
      await f.delete();
      return true;
    }
    return false;
  } catch (e) {
    print('Error deleting backup file: $e');
    return false;
  }
}

Future<String> formatBackupSize(BackupFileInfo file) async {
  final size = file.sizeBytes;
  if (size > 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (size > 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '$size B';
}

/// Lets the user pick a backup .json from anywhere on the device (e.g. one
/// they were sent via WhatsApp/email) — not used by the default mobile
/// restore flow (which lists internal backups instead), but available if
/// you want an "import from file" option later.
Future<PickedBackup?> pickBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.first;
  if (picked.path == null) return null;

  final content = await File(picked.path!).readAsString();
  return PickedBackup(name: picked.name, jsonContent: content);
}