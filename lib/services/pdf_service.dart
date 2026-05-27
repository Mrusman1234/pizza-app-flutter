import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generatePerformanceReport({
    required String title,
    required Map<String, dynamic> kpis,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> recentOrders,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(title),
            pw.SizedBox(height: 20),
            _buildKPIGrid(kpis),
            pw.SizedBox(height: 30),
            _buildSectionTitle('Top Selling Products'),
            _buildProductsTable(topProducts),
            pw.SizedBox(height: 30),
            _buildSectionTitle('Recent Orders'),
            _buildOrdersTable(recentOrders),
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Performance_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Text('Multi-Restaurant App', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
        ],
      ),
    );
  }

  static pw.Widget _buildKPIGrid(Map<String, dynamic> kpis) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: kpis.entries.map((e) {
        return pw.Container(
          width: 100,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(e.key, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 5),
              pw.Text(e.value.toString(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildProductsTable(List<Map<String, dynamic>> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Product Name', isHeader: true),
            _tableCell('Items Sold', isHeader: true),
            _tableCell('Revenue', isHeader: true),
          ],
        ),
        ...products.map((p) => pw.TableRow(
          children: [
            _tableCell(p['name'] ?? 'N/A'),
            _tableCell(p['count']?.toString() ?? '0'),
            _tableCell('Rs ${p['revenue']?.toStringAsFixed(0) ?? '0'}'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildOrdersTable(List<Map<String, dynamic>> orders) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Order ID', isHeader: true),
            _tableCell('Customer', isHeader: true),
            _tableCell('Amount', isHeader: true),
            _tableCell('Status', isHeader: true),
          ],
        ),
        ...orders.map((o) => pw.TableRow(
          children: [
            _tableCell(o['id']?.toString().substring(0, 8) ?? 'N/A'),
            _tableCell(o['userName'] ?? 'N/A'),
            _tableCell('Rs ${o['totalAmount']?.toStringAsFixed(0) ?? '0'}'),
            _tableCell(o['status'] ?? 'N/A'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Confidential Performance Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }
}
