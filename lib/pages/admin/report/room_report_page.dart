import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/services/cloud/room.dart';

import '../../../constants/route_constants.dart';
import '../../../services/cloud/firebase_cloud_storage.dart';
import '../../../services/cloud/loan.dart';

class RoomReportPage extends StatefulWidget {
  const RoomReportPage({super.key});

  @override
  State<RoomReportPage> createState() => _RoomReportPageState();
}

class _RoomReportPageState extends State<RoomReportPage> {
  int? _selectedMonth = DateTime.now().month;
  int? _selectedYear = DateTime.now().year;

  List<Room>? _rooms;

  DateTime _currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Data Ruangan'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  pdfViewRoomRoute,
                  arguments: [_rooms, _selectedMonth, _selectedYear],
                );
              },
              child: const Text('Cetak Laporan'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Room>>(
              stream: FirebaseCloudStorage().allRooms(),
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

                final rooms = snapshot.requireData;
                _rooms = rooms.docs.map((e) => e.data()).toList();
                log('$_rooms');

                return ListView.builder(
                  itemCount: rooms.size,
                  itemBuilder: (context, index) {
                    return ExpansionTile(
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      leading: Image.network(rooms.docs[index].data().image),
                      title: Text(rooms.docs[index].data().name),
                      children: [
                        Text(rooms.docs[index].data().description),
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
