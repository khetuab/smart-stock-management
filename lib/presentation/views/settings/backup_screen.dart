import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/backup_controller.dart';
import '../../controllers/dashboard_controller.dart';

class BackupScreen extends GetView<BackupController> {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('backupAndRestoreTitle'.tr),
        backgroundColor: Color(
          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
        ),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Backup Progress
              if (controller.isBackingUp.value) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${'creatingBackup'.tr} ${(controller.backupProgress.value * 100).toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: controller.backupProgress.value,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(
                            int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Last Backup Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'lastBackupLabel'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            controller.lastBackupDate.value.isEmpty
                                ? 'noBackupYet'.tr
                                : controller.lastBackupDate.value,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Backup Actions
              Text(
                'backupActionsSection'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup, color: Colors.blue),
                      title: Text('createBackupTitle'.tr),
                      subtitle: Text('createBackupSubtitle'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: controller.createBackup,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.orange),
                      title: Text('restoreBackupTitle'.tr),
                      subtitle: Text('restoreBackupSubtitle'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap:(){ controller.restoreBackup(context);},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Backup Files List
              Text(
                'backupFilesSection'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.backupFiles.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('noBackupFilesFound'.tr),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.backupFiles.length,
                  itemBuilder: (context, index) {
                    final file = controller.backupFiles[index];
                    final fileName = file.path.split('/').last;
                    final size = controller.getBackupSize(file);
                    final modified = file.lastModifiedSync();

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${modified.toLocal().toString().split(' ')[0]} • $size',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => controller.deleteBackupFile(file.path),
                        ),
                        onTap: () {
                          Get.snackbar(
                            'fileInfoTitle'.tr,
                            '${'fileLabel'.tr}: $fileName\n${'sizeLabel'.tr}: $size\n${'modifiedLabel'.tr}: ${modified.toLocal()}',
                            backgroundColor: Colors.blue,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                        },
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'aboutBackupTitle'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'aboutBackupDescription'.tr,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}