import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/services/cloud/tool.dart';
import 'package:silab/utilities/dialogs/dialogs.dart';

import '../../../services/cloud/loan.dart';

class DamagedToolReport extends StatefulWidget {
  const DamagedToolReport({Key? key}) : super(key: key);

  @override
  State<DamagedToolReport> createState() => _DamagedToolReportState();
}

class _DamagedToolReportState extends State<DamagedToolReport> {
  int? _selectedMonth = DateTime.now().month;
  int? _selectedYear = DateTime.now().year;

  List<Loan>? _loans;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kerusakan Alat'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () async {
                  log('$_loans');
                  // await showErrorDialog(
                  //     context, 'Data kerusakan alat belum tersedia');
                  Navigator.of(context).pushNamed(
                    pdfViewDamagedToolRoute,
                    arguments: [_loans, _selectedMonth, _selectedYear],
                  );
                },
                child: const Text('Cetak Laporan'),
              )
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Tool>>(
              stream: FirebaseCloudStorage()
                  .toolsCollection
                  .where('status', isEqualTo: 'Tidak Tersedia')
                  .snapshots(),
              builder: (context, snapshot) {
                log('${snapshot.data?.docs}');
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

                final tools = snapshot.requireData;
                log('$_loans');

                return ListView.builder(
                  itemCount: tools.size,
                  itemBuilder: (context, index) {
                    final tool = tools.docs[index].data();
                    return ExpansionTile(
                      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                      childrenPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                      leading: Image.network('${tool.image}'),
                      title: Text(tool.name),
                      children: [
                        Text(tool.description),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
