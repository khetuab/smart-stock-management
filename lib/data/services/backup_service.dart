import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'backup_platform/backup_platform.dart';
import 'backup_platform/backup_file_info.dart';
import 'google_sheets_service.dart';
import 'shared_preferences_service.dart';

class BackupService extends GetxService {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final SharedPreferencesService _prefs = SharedPreferencesService();

  var isBackingUp = false.obs;
  var backupProgress = 0.0.obs;
  var lastBackupDate = ''.obs;

  static const String backupFileName = 'smart_stock_backup.json';
  static const String backupFolder = 'SmartStockBackups';

  @override
  void onInit() {
    super.onInit();
    _loadLastBackupDate();
  }

  void _loadLastBackupDate() {
    lastBackupDate.value = _prefs.getString('lastBackupDate') ?? '';
  }

  /// Create a complete backup of all data
  Future<bool> createBackup() async {
    try {
      isBackingUp.value = true;
      backupProgress.value = 0.0;

      if (await _requestStoragePermission() == false) {
        Get.snackbar(
          'Permission Denied',
          'Storage permission is required for backup',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      await _sheets.init();

      final backupData = <String, dynamic>{};

      backupData['storeInfo'] = await _getStoreInfo();
      backupProgress.value = 0.2;

      backupData['products'] = await _getAllProducts();
      backupProgress.value = 0.4;

      backupData['sales'] = await _getAllSales();
      backupProgress.value = 0.6;

      backupData['purchases'] = await _getAllPurchases();
      backupProgress.value = 0.8;


      backupData['orders'] = await _getAllOrders();
      backupProgress.value = 0.75;

      backupData['users'] = await _getAllUsers();
      backupProgress.value = 0.9;

      backupData['settings'] = await _getSettings();
      backupProgress.value = 1.0;

      backupData['backupDate'] = DateTime.now().toIso8601String();
      backupData['appVersion'] = '1.0.0';
      backupData['backupId'] = _generateBackupId();

      final backupJson = jsonEncode(backupData);

      final file = await saveBackupJson(backupJson, auto: false);

      if (file != null) {
        await _prefs.setString('lastBackupDate', DateTime.now().toIso8601String());
        lastBackupDate.value = DateTime.now().toIso8601String();

        await shareBackupFile(
          file,
          subject: 'SmartStock Backup',
          text: 'SmartStock Backup - ${DateTime.now().toLocal().toString().split(' ')[0]}',
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Error creating backup: $e');
      return false;
    } finally {
      isBackingUp.value = false;
      backupProgress.value = 0.0;
    }
  }

  /// Create an automatic backup (without sharing)
  Future<bool> createAutoBackup() async {
    try {
      await _sheets.init();

      final backupData = <String, dynamic>{};
      backupData['storeInfo'] = await _getStoreInfo();
      backupData['products'] = await _getAllProducts();
      backupData['sales'] = await _getAllSales();
      backupData['purchases'] = await _getAllPurchases();
      backupData['users'] = await _getAllUsers();
      backupData['orders'] = await _getAllOrders();
      backupData['settings'] = await _getSettings();
      backupData['backupDate'] = DateTime.now().toIso8601String();
      backupData['appVersion'] = '1.0.0';
      backupData['backupId'] = _generateBackupId();

      final backupJson = jsonEncode(backupData);
      final file = await saveBackupJson(backupJson, auto: true);

      if (file != null) {
        await _prefs.setString('lastBackupDate', DateTime.now().toIso8601String());
        lastBackupDate.value = DateTime.now().toIso8601String();
        return true;
      }

      return false;
    } catch (e) {
      print('Error creating auto backup: $e');
      return false;
    }
  }

  /// Restore from a backup file
  Future<bool> restoreBackup(BuildContext context) async {
    try {
      isBackingUp.value = true;

      if (await _requestStoragePermission() == false) {
        Get.snackbar(
          'Permission Denied',
          'Storage permission is required for restore',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      String? jsonString;

      if (kIsWeb) {
        // Web has no persistent internal backup folder to list — go
        // straight to an upload picker instead of showing an empty list.
        final picked = await pickBackupFile();
        if (picked == null) {
          Get.snackbar(
            'Cancelled',
            'No backup file selected',
            colorText: Colors.orange,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
        jsonString = picked.jsonContent;
      } else {
        final file = await _pickBackupFile();
        if (file == null) {
          Get.snackbar(
            'Cancelled',
            'No backup file selected',
            colorText: Colors.orange,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
        jsonString = await readBackupFileContents(file);
      }

      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!_validateBackup(backupData)) {
        Get.snackbar(
          'Invalid Backup',
          'The selected file is not a valid backup',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final confirm = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFDC2626).withOpacity(0.15),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restore_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Restore Backup'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review snapshot contents before applying'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Get.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Created On:'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(backupData['backupDate'] ?? ''),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data Included'.tr.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            icon: Icons.inventory_2_rounded,
                            title: 'Products'.tr,
                            count: '${(backupData['products'] as List?)?.length ?? 0}',
                            accentColor: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            icon: Icons.receipt_long_rounded,
                            title: 'Sales'.tr,
                            count: '${(backupData['sales'] as List?)?.length ?? 0}',
                            accentColor: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This will overwrite all existing data in your app.'.tr,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Get.back(result: false),
                        child: Text(
                          'Cancel'.tr,
                          style: TextStyle(
                            color: Get.isDarkMode ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Get.back(result: true),
                        child: Text(
                          'Restore Data'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      if (confirm != true) {
        return false;
      }

      await _restoreStoreInfo(backupData['storeInfo']);
      await _restoreProducts(backupData['products']);
      await _restoreOrders(backupData['orders']);
      await _restoreSales(backupData['sales']);
      await _restorePurchases(backupData['purchases']);
      await _restoreUsers(backupData['users']);
      await _restoreSettings(backupData['settings']);

      Get.snackbar(
        'Success',
        'Backup restored successfully!',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      Get.snackbar(
        'Error',
        'Failed to restore backup: $e',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isBackingUp.value = false;
    }
  }

  Widget _buildMetricCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String count,
        required Color accentColor,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get all backup files (empty on web — see backup_platform_web.dart)
  Future<List<BackupFileInfo>> getBackupFiles() => listBackupFiles();

  /// Delete a backup file (no-op on web — nothing persists there)
  Future<bool> deleteBackup(BackupFileInfo file) => deleteBackupFile(file);

  /// Get backup size as a human-readable string
  Future<String> getBackupSize(BackupFileInfo file) => formatBackupSize(file);

  // MARK: - Private Methods

  Future<bool> _requestStoragePermission() => requestBackupPermission();

  Future<BackupFileInfo?> _pickBackupFile() async {
    try {
      final files = await listBackupFiles();
      if (files.isEmpty) {
        Get.snackbar(
          'No Backups',
          'No backup files found',
          colorText: Colors.orange,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      final selectedFile = await Get.dialog<BackupFileInfo>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Get.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(Get.context!).dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0891B2).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_zip_rounded,
                          color: Color(0xFF0891B2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Backup File'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Choose a backup to restore or manage'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: files.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final fileName = file.name;
                      final modified = file.modifiedDate;
                      final formattedDate =
                          '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}';

                      return FutureBuilder<String>(
                        future: formatBackupSize(file),
                        builder: (context, snapshot) {
                          final size = snapshot.data ?? '...';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Get.back(result: file),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Get.isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                  ),
                                  color: Get.isDarkMode
                                      ? Colors.grey.shade800.withOpacity(0.5)
                                      : Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.insert_drive_file_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  size,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final confirm = await _showDeleteConfirmation(
                                          context,
                                          fileName,
                                        );

                                        if (confirm == true) {
                                          await deleteBackupFile(file);
                                          Get.back(result: null);
                                          await _pickBackupFile();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(result: null),
                child: Text(
                  'Cancel'.tr,
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      return selectedFile;
    } catch (e) {
      print('Error picking backup file: $e');
      return null;
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String fileName) {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              'Delete Backup'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '${'Are you sure you want to delete'.tr} "$fileName"?',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );
  }

  // MARK: - Data Collection Methods

  Future<Map<String, dynamic>> _getStoreInfo() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('StoreInfo');
      if (data.isEmpty) return {};

      final storeInfo = <String, dynamic>{};
      final keys = data.keys.toList();

      for (var key in keys) {
        final values = data[key] ?? [];
        if (values.isNotEmpty) {
          storeInfo[key] = values.first;
        }
      }

      return storeInfo;
    } catch (e) {
      print('Error getting store info: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getAllProducts() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Products');
      if (data.isEmpty) return [];

      final products = <Map<String, dynamic>>[];
      final keys = data.keys.toList();

      for (int i = 0; i < (data[keys.first]?.length ?? 0); i++) {
        final product = <String, dynamic>{};
        for (var key in keys) {
          final values = data[key] ?? [];
          if (i < values.length) {
            product[key] = values[i];
          }
        }
        products.add(product);
      }

      return products;
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAllSales() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Sales');
      if (data.isEmpty) return [];

      final sales = <Map<String, dynamic>>[];
      final keys = data.keys.toList();

      for (int i = 0; i < (data[keys.first]?.length ?? 0); i++) {
        final sale = <String, dynamic>{};
        for (var key in keys) {
          final values = data[key] ?? [];
          if (i < values.length) {
            sale[key] = values[i];
          }
        }
        sales.add(sale);
      }

      return sales;
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAllPurchases() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Purchases');
      if (data.isEmpty) return [];

      final purchases = <Map<String, dynamic>>[];
      final keys = data.keys.toList();

      for (int i = 0; i < (data[keys.first]?.length ?? 0); i++) {
        final purchase = <String, dynamic>{};
        for (var key in keys) {
          final values = data[key] ?? [];
          if (i < values.length) {
            purchase[key] = values[i];
          }
        }
        purchases.add(purchase);
      }

      return purchases;
    } catch (e) {
      print('Error getting purchases: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAllUsers() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Users');
      if (data.isEmpty) return [];

      final users = <Map<String, dynamic>>[];
      final keys = data.keys.toList();

      for (int i = 0; i < (data[keys.first]?.length ?? 0); i++) {
        final user = <String, dynamic>{};
        for (var key in keys) {
          final values = data[key] ?? [];
          if (i < values.length) {
            user[key] = values[i];
          }
        }
        users.add(user);
      }

      return users;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAllOrders() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Orders');
      if (data.isEmpty) return [];

      final orders = <Map<String, dynamic>>[];
      final keys = data.keys.toList();

      for (int i = 0; i < (data[keys.first]?.length ?? 0); i++) {
        final order = <String, dynamic>{};
        for (var key in keys) {
          final values = data[key] ?? [];
          if (i < values.length) {
            order[key] = values[i];
          }
        }
        orders.add(order);
      }

      return orders;
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }
  Future<Map<String, dynamic>> _getSettings() async {
    return {
      'themeColor': _prefs.getThemeColor(),
      'currency': _prefs.getCurrency(),
      'language': _prefs.getLanguage(),
      'zakatEnabled': _prefs.isZakatEnabled(),
    };
  }

  // MARK: - Restore Methods

  Future<void> _restoreOrders(List<dynamic>? data) async {
    if (data == null || data.isEmpty) return;

    try {
      final orders = data.cast<Map<String, dynamic>>();
      if (orders.isEmpty) return;

      final headers = orders.first.keys.toList();
      final values = <List<dynamic>>[];
      values.add(headers);

      for (var order in orders) {
        final row = <dynamic>[];
        for (var key in headers) {
          row.add(order[key] ?? '');
        }
        values.add(row);
      }

      await _sheets.clearSheet('Orders');
      await _sheets.writeToSheet(
        sheetName: 'Orders',
        values: values,
      );
    } catch (e) {
      print('Error restoring orders: $e');
      rethrow;
    }
  }

  Future<void> _restoreStoreInfo(Map<String, dynamic>? data) async {
    if (data == null || data.isEmpty) return;

    try {
      final headers = data.keys.toList();
      final values = <List<dynamic>>[];
      values.add(headers);

      final row = <dynamic>[];
      for (var key in headers) {
        row.add(data[key] ?? '');
      }
      values.add(row);

      await _sheets.clearSheet('StoreInfo');
      await _sheets.writeToSheet(
        sheetName: 'StoreInfo',
        values: values,
      );
    } catch (e) {
      print('Error restoring store info: $e');
      rethrow;
    }
  }

  Future<void> _restoreProducts(List<dynamic>? data) async {
    if (data == null || data.isEmpty) return;

    try {
      final products = data.cast<Map<String, dynamic>>();
      if (products.isEmpty) return;

      final headers = products.first.keys.toList();
      final values = <List<dynamic>>[];
      values.add(headers);

      for (var product in products) {
        final row = <dynamic>[];
        for (var key in headers) {
          row.add(product[key] ?? '');
        }
        values.add(row);
      }

      await _sheets.clearSheet('Products');
      await _sheets.writeToSheet(
        sheetName: 'Products',
        values: values,
      );
    } catch (e) {
      print('Error restoring products: $e');
      rethrow;
    }
  }

  Future<void> _restoreSales(List<dynamic>? data) async {
    if (data == null || data.isEmpty) return;

    try {
      final sales = data.cast<Map<String, dynamic>>();
      if (sales.isEmpty) return;

      final headers = sales.first.keys.toList();
      final values = <List<dynamic>>[];
      values.add(headers);

      for (var sale in sales) {
        final row = <dynamic>[];
        for (var key in headers) {
          row.add(sale[key] ?? '');
        }
        values.add(row);
      }

      await _sheets.clearSheet('Sales');
      await _sheets.writeToSheet(
        sheetName: 'Sales',
        values: values,
      );
    } catch (e) {
      print('Error restoring sales: $e');
      rethrow;
    }
  }

  Future<void> _restorePurchases(List<dynamic>? data) async {
    if (data == null || data.isEmpty) return;

    try {
      final purchases = data.cast<Map<String, dynamic>>();
      if (purchases.isEmpty) return;

      final headers = purchases.first.keys.toList();
      final values = <List<dynamic>>[];
      values.add(headers);

      for (var purchase in purchases) {
        final row = <dynamic>[];
        for (var key in headers) {
          row.add(purchase[key] ?? '');
        }
        values.add(row);
      }

      await _sheets.clearSheet('Purchases');
      await _sheets.writeToSheet(
        sheetName: 'Purchases',
        values: values,
      );
    } catch (e) {
      print('Error restoring purchases: $e');
      rethrow;
    }
  }

  Future<void> _restoreUsers(List<dynamic>? data) async {
    if (data == null || data.isEmpty) return;

    try {
      final users = data.cast<Map<String, dynamic>>();
      if (users.isEmpty) return;

      final headers = users.first.keys.toList();
      final values = <List<dynamic>>[];
      values.add(headers);

      for (var user in users) {
        final row = <dynamic>[];
        for (var key in headers) {
          row.add(user[key] ?? '');
        }
        values.add(row);
      }

      await _sheets.clearSheet('Users');
      await _sheets.writeToSheet(
        sheetName: 'Users',
        values: values,
      );
    } catch (e) {
      print('Error restoring users: $e');
      rethrow;
    }
  }

  Future<void> _restoreSettings(Map<String, dynamic>? data) async {
    if (data == null) return;

    try {
      if (data['themeColor'] != null) {
        await _prefs.setString('themeColor', data['themeColor'].toString());
      }
      if (data['currency'] != null) {
        await _prefs.setString('currency', data['currency'].toString());
      }
      if (data['language'] != null) {
        await _prefs.setString('language', data['language'].toString());
      }
      if (data['zakatEnabled'] != null) {
        await _prefs.setBool('zakatEnabled', data['zakatEnabled'] as bool);
      }
    } catch (e) {
      print('Error restoring settings: $e');
      rethrow;
    }
  }

  bool _validateBackup(Map<String, dynamic> data) {
    return data.containsKey('backupId') &&
        data.containsKey('backupDate') &&
        data.containsKey('appVersion') &&
        data.containsKey('storeInfo');
  }

  String _generateBackupId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'BK_${timestamp}_$random';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.toLocal().toString().split(' ')[0];
    } catch (e) {
      return dateString;
    }
  }
}