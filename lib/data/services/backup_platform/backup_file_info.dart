class BackupFileInfo {
  final String name;
  final String? path; // null on web — there's no filesystem path there
  final int sizeBytes;
  final DateTime modifiedDate;

  const BackupFileInfo({
    required this.name,
    this.path,
    required this.sizeBytes,
    required this.modifiedDate,
  });
}

class PickedBackup {
  final String name;
  final String jsonContent;

  const PickedBackup({required this.name, required this.jsonContent});
}