import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/services/receipt_service.dart';
import '../../controllers/sale_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';

class SaleDetailScreen extends GetView<SaleController> {
  final Sale? sale;

  const SaleDetailScreen({super.key, this.sale});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;

    final Sale? saleData = sale ?? Get.arguments as Sale?;

    if (saleData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('saleNotFoundTitle'.tr)),
        body: AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'saleNotFoundTitle'.tr,
          subtitle: 'saleNotFoundSubtitle'.tr,
        ),
      );
    }

    final tone = saleData.status == 'completed'
        ? PillTone.success
        : saleData.status == 'cancelled'
        ? PillTone.error
        : PillTone.warning;

    return Scaffold(
      appBar: AppBar(
        title: Text('saleDetailsTitle'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => _printReceipt(context, saleData),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'saleIdLabel'.tr,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        '#${saleData.id.isNotEmpty ? saleData.id.substring(0, saleData.id.length < 8 ? saleData.id.length : 8).toUpperCase() : 'notAvailable'.tr}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface),
                      ),
                    ],
                  ),
                  StatusPill(text: saleData.status.toUpperCase(), tone: tone),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'productInformationHeader'.tr,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  DetailRow(label: 'productNameLabel'.tr, value: saleData.productName),
                  DetailRow(label: 'quantityLabel'.tr, value: saleData.quantity.toString()),
                  DetailRow(label: 'unitPriceLabel'.tr, value: dashboardController.formatCurrency(saleData.sellingPrice)),
                  DetailRow(label: 'totalLabel'.tr, value: dashboardController.formatCurrency(saleData.total)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SectionCard(
              child: Column(
                children: [
                  DetailRow(label: 'dateLabel'.tr, value: saleData.date.isNotEmpty ? saleData.date : 'notAvailable'.tr),
                  DetailRow(label: 'timeLabel'.tr, value: saleData.time.isNotEmpty ? saleData.time : 'notAvailable'.tr),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReceipt(context, saleData),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text('shareReceiptButton'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadReceipt(context, saleData),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('downloadButton'.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _printReceipt(context, saleData),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: Text('printButton'.tr),
              ),
            ),
            const SizedBox(height: 20),

            if (saleData.status != 'cancelled')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelSale(context, saleData),
                  icon: Icon(Icons.cancel_rounded, color: scheme.error),
                  label: Text('cancelSaleButton'.tr, style: TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: scheme.error)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _receiptFilename(Sale sale) {
    final shortId = sale.id.isNotEmpty
        ? sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase()
        : 'receipt';
    return 'receipt_$shortId.pdf';
  }

  Future<void> _shareReceipt(BuildContext context, Sale sale) async {
    final dashboardController = Get.find<DashboardController>();
    try {
      final bytes = await ReceiptService.generate(
        sale: sale,
        storeName: dashboardController.storeName.value,
        formatCurrency: dashboardController.formatCurrency,
      );
      await Printing.sharePdf(bytes: bytes, filename: _receiptFilename(sale));
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to share receipt: $e',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _printReceipt(BuildContext context, Sale sale) async {
    final dashboardController = Get.find<DashboardController>();
    try {
      await Printing.layoutPdf(
        name: _receiptFilename(sale),
        onLayout: (format) => ReceiptService.generate(
          sale: sale,
          storeName: dashboardController.storeName.value,
          formatCurrency: dashboardController.formatCurrency,
          pageFormat: format,
        ),
      );
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to print receipt: $e',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _downloadReceipt(BuildContext context, Sale sale) async {
    final dashboardController = Get.find<DashboardController>();
    try {
      final bytes = await ReceiptService.generate(
        sale: sale,
        storeName: dashboardController.storeName.value,
        formatCurrency: dashboardController.formatCurrency,
      );

      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${dir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final file = File('${receiptsDir.path}/${_receiptFilename(sale)}');
      await file.writeAsBytes(bytes);

      Get.snackbar(
        'success'.tr,
        'Receipt saved',
        colorText: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () => OpenFile.open(file.path),
          child: const Text('OPEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to save receipt: $e',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _cancelSale(BuildContext context, Sale sale) async {
    final scheme = Theme.of(context).colorScheme;
    final shortId = sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase();

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('cancelSaleDialogTitle'.tr),
        content: Text(
          'cancelSaleConfirmationMessage'.trParams({'id': shortId}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('noButton'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text('yesCancelButton'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement sale cancellation (restore product quantities, mark as cancelled).
      Get.snackbar(
        'successSnackbarTitle'.tr,
        'saleCancelledSuccessMessage'.tr,
        colorText: const Color(0xFF15803D),
        snackPosition: SnackPosition.BOTTOM
      );
      await Get.find<SaleController>().loadSales();
      Get.back();
    }
  }
}