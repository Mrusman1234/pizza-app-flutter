import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../core/constants/app_strings.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateAndPrintInvoice(OrderModel order) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    final timeStr = DateFormat('hh:mm a').format(order.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppStrings.appName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Vehari, Pakistan', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                      pw.Text('Order # ${order.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Customer & Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.userName ?? order.userId, style: const pw.TextStyle(fontSize: 10)),
                      pw.Container(width: 200, child: pw.Text(order.deliveryAddress, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: $dateStr'),
                      pw.Text('Time: $timeStr'),
                      pw.Text('Payment: ${order.paymentMethod}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Table Header
              pw.Container(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Expanded(child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Expanded(child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),

              // Table Body
              ...order.items.map((item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.pizza.name)),
                      pw.Expanded(child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center)),
                      pw.Expanded(child: pw.Text('Rs. ${item.itemPrice.toInt()}', textAlign: pw.TextAlign.right)),
                      pw.Expanded(child: pw.Text('Rs. ${(item.itemPrice * item.quantity).toInt()}', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 20),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Subtotal: '),
                          pw.Text('Rs. ${(order.subtotal ?? (order.totalAmount - (order.deliveryFee ?? 0) - (order.tax ?? 0))).toInt()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Delivery Fee: Rs. ${(order.deliveryFee ?? 0).toInt()}'),
                      pw.Text('Tax (GST): Rs. ${(order.tax ?? 0).toInt()}'),
                      pw.Divider(color: PdfColors.grey),
                      pw.Row(
                        children: [
                          pw.Text('Grand Total: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs. ${order.totalAmount.toInt()}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for ordering from Pizza O\'Clock!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600))),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> generatePerformanceReport({
    required String title,
    required Map<String, String> kpis,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> recentOrders,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Key Performance Indicators:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ...kpis.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
            pw.SizedBox(height: 20),
            pw.Text('Summary generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
