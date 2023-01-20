import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';

import '../../../services/cloud/tool.dart';

class ToolReportPage extends StatefulWidget {
  const ToolReportPage({super.key});

  @override
  State<ToolReportPage> createState() => _ToolReportPageState();
}

class _ToolReportPageState extends State<ToolReportPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Data Alat'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(pdfViewToolRoute);
                    },
                    child: const Text('Cetak Laporan'),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Data Alat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Tool>>(
                  stream: FirebaseCloudStorage().allTools(),
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

                    final tools = snapshot.requireData;
                    return ListView.builder(
                      itemCount: tools.size,
                      itemBuilder: (context, index) {
                        final tool = tools.docs[index].data();

                        return ExpansionTile(
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
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
        ));
  }
}
