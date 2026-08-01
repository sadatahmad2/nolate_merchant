import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptGenerator {
  static Future<void> generateAndDownloadReceipt({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String shopName,
    required List<Map<String, dynamic>> items, 
    // item should have: 'name': String, 'quantity': int, 'price': double
    required double subtotal,
    required double tax,
    required double deliveryFee,
    required double total,
    required DateTime date,
    String? riderName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nolate Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Order #${orderId.substring(0, 8)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(shopName),
                      pw.SizedBox(height: 10),
                      pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customerName.isEmpty ? 'Customer' : customerName),
                      if (customerPhone.isNotEmpty) pw.Text(customerPhone),
                      if (customerAddress.isNotEmpty) pw.Text(customerAddress),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                      if (riderName != null && riderName.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Text('Delivered By:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(riderName),
                      ],
                    ],
                  )
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Items Table
              pw.Table.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Total'],
                data: items.map((item) {
                  final qty = (item['quantity'] as num).toInt();
                  final price = (item['price'] as num).toDouble();
                  return [
                    item['name'].toString(),
                    qty.toString(),
                    'Rs ${price.toStringAsFixed(2)}',
                    'Rs ${(qty * price).toStringAsFixed(2)}'
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: Rs ${subtotal.toStringAsFixed(2)}'),
                      pw.Text('Tax: Rs ${tax.toStringAsFixed(2)}'),
                      pw.Text('Delivery Fee: Rs ${deliveryFee.toStringAsFixed(2)}'),
                      pw.Divider(),
                      pw.Text('Total: Rs ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ]
                  )
                ]
              ),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Thank you for shopping with Nolate!', style: const pw.TextStyle(color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    // This will open a dialog to share/save/print the PDF
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'nolate_receipt_${orderId.substring(0, 8)}.pdf');
  }
}
