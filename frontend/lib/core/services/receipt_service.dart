import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  /// Generates a PDF receipt and shows the print/preview dialog
  static Future<void> printReceipt({
    required String invoiceNumber,
    required String businessName,
    required String? customerName,
    required String paymentStatus,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    this.discount = 0.0,
    required double paidAmount,
    required double debtAmount,
    required DateTime saleDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 80mm thermal paper
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'RASIIDKA IIBKA',
                      style: pw.TextStyle(fontSize: 13),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Invoice: $invoiceNumber',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(saleDate),
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    if (customerName != null)
                      pw.Text(
                        'Macmiilka: $customerName',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
              pw.Divider(),
              
              // Column Headers
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Alaabta', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Qiimaha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Wadarta', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(height: 4),

              // Items
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        item['name'] ?? '',
                        style: const pw.TextStyle(fontSize: 9),
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        '${item['quantity']}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '\$${item['price']}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '\$${item['subtotal']}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),

              pw.Divider(),

              // Totals
              if (discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diiskaawan (Discount):', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('-\$$discount', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Wadarta Guud:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('\$$totalAmount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('La Bixiyey:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('\$$paidAmount', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (debtAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Deynta:', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)),
                    pw.Text('\$$debtAmount', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)),
                  ],
                ),
              
              pw.Divider(),

              // Payment Status
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: paymentStatus == 'paid' ? PdfColors.green : PdfColors.orange),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    paymentStatus == 'paid' ? '✓ LACAG LA BIXIYEY' : '⚠ DEYN',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: paymentStatus == 'paid' ? PdfColors.green : PdfColors.orange,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Mahadsanid xididdada!', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('BookSafe ERP System', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt-$invoiceNumber',
    );
  }
}
