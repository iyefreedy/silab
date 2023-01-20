import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';

import '../../services/cloud/loan.dart';

Future<void> showLoanDialog(BuildContext context, Loan loan) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Detail Peminjaman'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<AuthUser>(
              future: FirebaseCloudStorage().getUserById(userId: loan.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('');
                }

                if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                final user = snapshot.requireData;
                return Text(user.name!);
              },
            ),
            Text(
                'Waktu Peminjaman : ${DateFormat('dd-MM-yyyy').format(loan.startTime)}'),
            Text(
                'Jam : ${DateFormat('HH:mm').format(loan.startTime)} s/d ${DateFormat('HH:mm').format(loan.endTime)}'),
            Text('Ruang : ${loan.room?.name}'),
            const Text('Alat yang di pinjam'),
            ...loan.tools.map((e) => Text('${e.name} : ${e.quantity}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Ok'),
          )
        ],
      );
    },
  );
}
