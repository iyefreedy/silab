import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/pages/admin/pdf/create_loan_report_pdf.dart.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/utilities/dialogs/dialogs.dart';
import 'package:silab/utilities/utils.dart';

import '../../../services/cloud/loan.dart';

class LoanReportPage extends StatefulWidget {
  const LoanReportPage({Key? key}) : super(key: key);

  @override
  State<LoanReportPage> createState() => _LoanReportPageState();
}

class _LoanReportPageState extends State<LoanReportPage> {
  int? _selectedMonth = DateTime.now().month;
  int? _selectedYear = DateTime.now().year;

  final Map<String, int> months = {
    'Januari': 1,
    'Februari': 2,
    'Maret': 3,
    'April': 4,
    'Mei': 5,
    'Juni': 6,
    'Juli': 7,
    'Agustus': 8,
    'September': 9,
    'Oktober': 10,
    'November': 11,
    'Desember': 12,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Peminjaman'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          reportOption,
          StreamBuilder<QuerySnapshot<Loan>>(
            stream: FirebaseCloudStorage().getLoanBySelectedTime(
              month: _selectedMonth,
              year: _selectedYear,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }

              final loans = snapshot.requireData;

              return _ToolTable(
                loans: loans,
              );
            },
          ),
        ],
      ),
    );
  }

  Padding get reportOption {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          monthDropdown,
          yearDropdown,
          reportButton,
        ],
      ),
    );
  }

  Expanded get reportButton {
    return Expanded(
      child: ElevatedButton(
        onPressed: () async {
          final loans = await FirebaseCloudStorage()
              .loansCollection
              .where('start_time',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                      DateTime(_selectedYear ?? DateTime.now().year)))
              .orderBy('start_time', descending: true)
              .get();
          if (loans.docs.isEmpty) {
            if (!mounted) return;
            await showErrorDialog(
              context,
              'Tidak ada data peminjman',
            );
            return;
          }

          if (!mounted) return;
          Navigator.of(context).pushNamed(
            pdfViewLoanRoute,
            arguments: LoanArgument(
              _selectedYear ?? DateTime.now().year,
              _selectedMonth ?? DateTime.now().month,
            ),
          );
        },
        child: const Text('Cetak Laporan'),
      ),
    );
  }

  DropdownButton<int> get yearDropdown {
    return DropdownButton<int>(
      hint: const Text('Pilih Tahun'),
      value: _selectedYear,
      items: [
        for (var i = 2018; i <= 2022; i++)
          DropdownMenuItem(
            value: i,
            child: Text('$i'),
          ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedYear = value;
        });
      },
    );
  }

  DropdownButton<int> get monthDropdown {
    return DropdownButton<int>(
      hint: const Text('Pilih Bulan'),
      value: _selectedMonth,
      items: months.keys
          .map((e) => DropdownMenuItem<int>(
                value: months[e],
                child: Text(e),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedMonth = value;
        });
      },
    );
  }
}

class _ToolTable extends StatelessWidget {
  const _ToolTable({
    required this.loans,
  });

  final QuerySnapshot<Loan> loans;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
            label: Text('Nama Peminjam'),
          ),
          DataColumn(
            label: Text('Tanggal Peminjaman'),
          ),
          DataColumn(
            label: Text('Waktu Peminjaman'),
          ),
        ],
        rows: loans.docs
            .map((e) => DataRow(
                  cells: [
                    DataCell(
                      FutureBuilder<AuthUser>(
                        future: FirebaseCloudStorage()
                            .getUserById(userId: e.data().userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.hasError) {
                            return const Text('-');
                          }

                          final user = snapshot.requireData;
                          return Text('${user.name}');
                        },
                      ),
                    ),
                    DataCell(
                      Text(
                        formatDateTime(e.data().startTime, 'dd-MM-yyyy'),
                      ),
                    ),
                    DataCell(Text(
                        '${formatDateTime(e.data().startTime, 'HH:mm')} - ${formatDateTime(e.data().endTime, 'HH:mm')}')),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
