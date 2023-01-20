import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../../extensions/datetime/compare_date.dart';
import '../../../services/cloud/loan.dart';

class LoanArgument {
  final int year;
  final int month;

  LoanArgument(this.year, this.month);
}

class CreateLoanReportPdf extends StatelessWidget {
  const CreateLoanReportPdf({
    super.key,
    required this.argument,
  });
  final LoanArgument argument;

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      canChangeOrientation: true,
      build: (format) async {
        pw.Document docs = pw.Document();
        final memoryImage = await getLogoFromAssets();
        final startDay =
            Timestamp.fromDate(DateTime(argument.year, argument.month, 1));
        final endDay =
            Timestamp.fromDate(DateTime(argument.year, argument.month, 30));
        final loansQuery = await FirebaseCloudStorage()
            .loansCollection
            .where(
              'start_time',
              isLessThanOrEqualTo: endDay,
              isGreaterThan: startDay,
            )
            .get();

        final loans = loansQuery.docs.map((e) => e.data()).toList();
        log('$loans');
        final usersFuture = loans.map((e) async {
          return await FirebaseCloudStorage().getUserById(userId: e.userId);
        });

        final users = await Future.wait(usersFuture);

        docs.addPage(pw.Page(
          orientation: pw.PageOrientation.landscape,
          build: (context) {
            return pw.Container(
              child: pw.Column(children: [
                _buildReportHeader(memoryImage, context),
                pw.SizedBox(height: 16.0),
                pw.Table.fromTextArray(
                  headers: [
                    'No.',
                    'Nama Peminjam',
                    'Tanggal Peminjaman',
                    'Jam Mulai',
                    'Jam Selesai',
                    'Keterangan',
                    'Unit',
                  ],
                  data: List.generate(
                    loans.length,
                    (index) => [
                      index + 1,
                      users[index].name,
                      DateFormat('dd MM yyyy').format(loans[index].startTime),
                      DateFormat('HH:mm').format(loans[index].startTime),
                      DateFormat('HH:mm').format(loans[index].endTime),
                      loans[index].room?.name,
                      loans[index].tools.map((e) => e.name),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24.0),
                footnote,
              ]),
            );
          },
        ));

        return await docs.save();
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

  pw.Container _buildReportHeader(
    pw.MemoryImage memoryImage,
    pw.Context context,
  ) {
    final DateTime selectedDate = DateTime(argument.year, argument.month);
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
                pw.Text(
                  'Universitas Al-Azhar Indonesia',
                  style: pw.Theme.of(context).header5.copyWith(fontSize: 8.0),
                ),
              ],
            ),
          ),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Laporan Data Peminjaman',
                  style: pw.Theme.of(context).header1,
                ),
                pw.Text(DateFormat('MMMM yyyy', 'id').format(selectedDate))
              ],
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
}
