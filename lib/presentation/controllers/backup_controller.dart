import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/data/services/backup_platform/backup_file_info.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/shared_preferences_service.dart';

class BackupController extends GetxController {
  final BackupService _backupService = BackupService();
  final SharedPreferencesService _prefs = SharedPreferencesService();

  var isLoading = false.obs;
  var isBackingUp = false.obs;
  var backupProgress = 0.0.obs;
  var backupFiles = <File>[].obs;
  var lastBackupDate = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBackupFiles();
    loadLastBackupDate();
  }

  void loadLastBackupDate() {
    lastBackupDate.value = _prefs.getString('lastBackupDate') ?? '';
  }

  Future<void> loadBackupFiles() async {
    try {
      isLoading.value = true;
      backupFiles.value = (await _backupService.getBackupFiles()).cast<File>();
    } catch (e) {
      print('Error loading backup files: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createBackup() async {
    try {
      isBackingUp.value = true;
      backupProgress.value = 0.0;

      final result = await _backupService.createAutoBackup();

      if (result) {
        await loadBackupFiles();
        loadLastBackupDate();

        Get.snackbar(
          'Success',
          'Backup created successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create backup',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
      }

    } catch (e) {
      print('Error creating backup: $e');
      Get.snackbar(
        'Error',
        'Failed to create backup: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isBackingUp.value = false;
      backupProgress.value = 0.0;
    }
  }

  Future<void> restoreBackup(BuildContext context) async {
    try {
      isLoading.value = true;

      final result = await _backupService.restoreBackup(context);

      if (result) {
        await loadBackupFiles();
        loadLastBackupDate();

        Get.snackbar(
          'Success',
          'Backup restored successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      }

    } catch (e) {
      print('Error restoring backup: $e');
      Get.snackbar(
        'Error',
        'Failed to restore backup: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBackupFile(String filePath) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Backup File'),
        content: Text('Are you sure you want to delete this backup file?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isLoading.value = true;

      final result = await _backupService.deleteBackup(filePath as BackupFileInfo);

      if (result) {
        await loadBackupFiles();
        Get.snackbar(
          'Success',
          'Backup file deleted successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete backup file',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
      }

    } catch (e) {
      print('Error deleting backup file: $e');
      Get.snackbar(
        'Error',
        'Failed to delete backup file: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  String getBackupSize(File file) {
    try {
      final size = file.lengthSync();
      if (size > 1024 * 1024) {
        return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else if (size > 1024) {
        return '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        return '$size B';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}