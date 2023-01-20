import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/services/cloud/room.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../../extensions/datetime/compare_date.dart';

class CreateRoomReportPdfRoute extends StatelessWidget {
  const CreateRoomReportPdfRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      initialPageFormat: PdfPageFormat.a4,
      build: (format) async {
        final roomsQuery = await FirebaseCloudStorage().roomsCollection.get();
        final memoryImage = await getLogoFromAssets();
        final rooms = roomsQuery.docs.map((e) => e.data()).toList();

        pw.Document docs = pw.Document();
        docs.addPage(pw.Page(
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
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 40.0,
                ),
                child: pw.Column(
                  children: [
                    _buildReportHeader(memoryImage, context),
                    pw.SizedBox(height: 20.0),
                    _buildDataTable(rooms),
                    pw.SizedBox(height: 50.0),
                    footnote,
                  ],
                ),
              );
            }));

        return await docs.save();
      },
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
              'Laporan Data Ruangan',
              style: pw.Theme.of(context).header1,
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.MemoryImage> getLogoFromAssets() async {
    final memoryImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo-silab-cropped.png'))
          .buffer
          .asUint8List(),
    );
    return memoryImage;
  }

  pw.Table _buildDataTable(List<Room> rooms) {
    return pw.Table.fromTextArray(
      headers: [
        'No.',
        'Nama Alat',
        'Keterangan',
      ],
      data: List.generate(
        rooms.length,
        (index) => [
          index + 1,
          rooms[index].name,
          rooms[index].description,
        ],
      ),
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
}

Future<Uint8List> makeLoanReport(List<Room>? object, DateTime dateTime) async {
  final pdf = pw.Document();

  assert(object != null);
  final list = object!;

  final header = pw.Text(
    'Laporan Peminjaman Ruangan',
    style: pw.TextStyle(
      fontSize: 20.0,
      fontWeight: pw.FontWeight.bold,
    ),
  );
  final table = pw.Table(
    border: pw.TableBorder.all(),
    children: [
      pw.TableRow(
        children: [
          pw.Text('Kode Ruang'),
          pw.Text('Nama Ruang'),
          pw.Text('Keterangan Ruang'),
        ],
      ),
      ...list.map((e) {
        return pw.TableRow(
          children: [
            pw.Text(DateTime.now().microsecondsSinceEpoch.toString()),
            pw.Text(e.name),
            pw.Text(e.description),
          ],
        );
      }),
    ],
  );

  pdf.addPage(pw.Page(
    build: (context) {
      return pw.Column(children: [
        header,
        pw.Text('Bulan ${DateFormat('MMMM y').format(dateTime)}'),
        pw.SizedBox(height: 15.0),
        table,
      ]);
    },
  ));

  return await pdf.save();
}
