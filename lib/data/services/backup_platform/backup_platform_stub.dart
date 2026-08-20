import 'backup_file_info.dart';

Future<bool> requestBackupPermission() async => false;
Future<BackupFileInfo?> saveBackupJson(String jsonData, {required bool auto}) async => null;
Future<void> shareBackupFile(BackupFileInfo file, {required String subject, required String text}) async {}
Future<List<BackupFileInfo>> listBackupFiles() async => [];
Future<String> readBackupFileContents(BackupFileInfo file) async => '';
Future<bool> deleteBackupFile(BackupFileInfo file) async => false;
Future<String> formatBackupSize(BackupFileInfo file) async => 'Unknown';
Future<PickedBackup?> pickBackupFile() async => null;