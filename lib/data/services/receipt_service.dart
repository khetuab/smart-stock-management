import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sale_model.dart';

/// Builds a clean, professional PDF receipt for a single sale.
/// Kept as pure PDF generation — no Flutter widget/BuildContext dependency —
/// so it can be reused by print, share, and save without duplicating layout.
class ReceiptService {
  static Future<Uint8List> generate({
    required Sale sale,
    required String storeName,
    required String Function(double) formatCurrency,
    PdfPageFormat pageFormat = PdfPageFormat.a5,
  }) async {
    final doc = pw.Document();
    final shortId = sale.id.isNotEmpty
        ? sale.id.substring(0, sale.id.length < 8 ? sale.id.length : 8).toUpperCase()
        : 'N/A';

    final borderColor = PdfColor.fromInt(0xFFE2E8F0);
    final mutedColor = PdfColor.fromInt(0xFF64748B);
    final darkColor = PdfColor.fromInt(0xFF111827);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Header ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      storeName.isEmpty ? 'Smart Shop' : storeName,
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Sales receipt',
                      style: pw.TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 12),

              // --- Meta row ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _metaBlock('Receipt no.', '#$shortId', mutedColor, darkColor),
                  _metaBlock(
                    'Date',
                    '${sale.date.isNotEmpty ? sale.date : '-'}  ${sale.time.isNotEmpty ? sale.time : ''}',
                    mutedColor,
                    darkColor,
                    alignEnd: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              _metaBlock('Status', sale.status.toUpperCase(), mutedColor, darkColor),

              pw.SizedBox(height: 18),

              // --- Item table ---
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                ),
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 4, child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, color: mutedColor))),
                    pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, color: mutedColor))),
                    pw.Expanded(flex: 3, child: pw.Text('Unit', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: mutedColor))),
                    pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: mutedColor))),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: pw.Text(sale.productName, style: pw.TextStyle(fontSize: 11, color: darkColor))),
                  pw.Expanded(flex: 2, child: pw.Text(sale.quantity.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 11, color: darkColor))),
                  pw.Expanded(flex: 3, child: pw.Text(formatCurrency(sale.sellingPrice), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, color: darkColor))),
                  pw.Expanded(flex: 3, child: pw.Text(formatCurrency(sale.total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, color: darkColor))),
                ],
              ),

              pw.SizedBox(height: 18),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 10),

              // --- Totals block ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkColor)),
                  pw.Text(
                    formatCurrency(sale.total),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkColor),
                  ),
                ],
              ),

              if (sale.isCredit) ...[
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid', style: pw.TextStyle(fontSize: 11, color: mutedColor)),
                    pw.Text(formatCurrency(sale.amountPaid), style: pw.TextStyle(fontSize: 11, color: darkColor)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Balance due', style: pw.TextStyle(fontSize: 11, color: mutedColor)),
                    pw.Text(
                      formatCurrency(sale.balanceDue),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFDC2626)),
                    ),
                  ],
                ),
                if (sale.customerName.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Customer', style: pw.TextStyle(fontSize: 11, color: mutedColor)),
                      pw.Text(sale.customerName, style: pw.TextStyle(fontSize: 11, color: darkColor)),
                    ],
                  ),
                ],
              ],

              pw.SizedBox(height: 28),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business',
                  style: pw.TextStyle(fontSize: 11, color: mutedColor),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _metaBlock(
      String label,
      String value,
      PdfColor mutedColor,
      PdfColor darkColor, {
        bool alignEnd = false,
      }) {
    return pw.Column(
      crossAxisAlignment: alignEnd ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: mutedColor)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkColor)),
      ],
    );
  }
}