import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:silab/extensions/datetime/compare_date.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/services/cloud/tool.dart';

class CreateDamagedToolReportPdf extends StatelessWidget {
  const CreateDamagedToolReportPdf({super.key});

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      initialPageFormat: PdfPageFormat.a4,
      build: (format) async {
        final toolsQuery = await FirebaseCloudStorage()
            .toolsCollection
            .where('status', isEqualTo: 'Tidak Tersedia')
            .get();
        final tools = toolsQuery.docs.map((e) => e.data()).toList();
        final memoryImage = pw.MemoryImage(
          (await rootBundle.load('assets/images/logo-silab-cropped.png'))
              .buffer
              .asUint8List(),
        );

        final doc = pw.Document();
        doc.addPage(pw.Page(
          orientation: pw.PageOrientation.portrait,
          margin: const pw.EdgeInsets.only(
            top: 4,
            left: 4,
            bottom: 3,
            right: 3,
          ),
          pageFormat: PdfPageFormat.a4.copyWith(
            marginBottom: 3,
            marginLeft: 4,
            marginTop: 4,
            marginRight: 3,
          ),
          build: (context) {
            log('${format.marginLeft}');
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 40.0,
              ),
              child: pw.Column(
                children: [
                  _buildReportHeader(memoryImage, context),
                  pw.SizedBox(height: 20.0),
                  _buildDataTable(tools),
                  pw.SizedBox(height: 50.0),
                  footnote,
                ],
              ),
            );
          },
        ));

        return await doc.save();
      },
    );
  }

  pw.Align get footnote {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        children: [
          pw.Text(
              'Jakarta, ${IdFormat.ddMMMMyyyy('id').format(DateTime.now())}'),
          pw.Text('Kepala Laboratorium'),
          pw.SizedBox(height: 50.0),
          pw.Text('Lutfi Sani, S.Kom',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              )),
        ],
      ),
    );
  }

  pw.Table _buildDataTable(List<Tool> tools) {
    return pw.Table.fromTextArray(
      tableWidth: pw.TableWidth.max,
      headers: [
        'No.',
        'Nama Alat',
        'Keterangan',
        'Tanggal Beli',
        'Status',
      ],
      data: List.generate(
        tools.length,
        (index) => [
          index + 1,
          tools[index].name,
          tools[index].description,
          DateFormat('dd-MM-yyyy').format(tools[index].purchasedDate),
          tools[index].status,
        ],
      ),
    );
  }

  pw.Container _buildReportHeader(
      pw.MemoryImage memoryImage, pw.Context context) {
    return pw.Container(
      height: 100,
      child: pw.Stack(
        children: [
          pw.Positioned(
            top: 20.0,
            child: pw.Column(
              children: [
                pw.Image(
                  memoryImage,
                  height: 65.0,
                ),
                pw.Text('Universitas Al-Azhar Indonesia'),
              ],
            ),
          ),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Laporan Data Kerusakan Alat',
              style: pw.Theme.of(context).header1,
            ),
          ),
        ],
      ),
    );
  }
}
