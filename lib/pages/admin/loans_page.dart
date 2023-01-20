import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/enums/loan_status.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/services/cloud/loan.dart';
import 'package:silab/utilities/dialogs/confirmation_dialog.dart';
import 'package:silab/utilities/utils.dart';

class LoansPage extends StatelessWidget {
  const LoansPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: LoanStatus.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Peminjaman'),
          bottom: TabBar(
            tabs: LoanStatus.values
                .map((e) => Tab(
                      child: Text(e.name),
                    ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: LoanStatus.values
              .map(
                (e) => StreamBuilder<QuerySnapshot<Loan>>(
                  stream: FirebaseCloudStorage().allLoans(status: e),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final loans = snapshot.requireData;
                    if (loans.size < 1) {
                      return const Center(
                        child: Text('Belum Ada Data'),
                      );
                    }

                    return _LoanList(loans: loans);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  const _LoanList({
    Key? key,
    required this.loans,
  }) : super(key: key);

  final QuerySnapshot<Loan> loans;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: loans.size,
      itemBuilder: (context, index) {
        return _LoanItem(
          loan: loans.docs[index].data(),
          reference: loans.docs[index].reference,
        );
      },
    );
  }
}

class _LoanItem extends StatefulWidget {
  const _LoanItem({
    Key? key,
    required this.loan,
    required this.reference,
  }) : super(key: key);

  final Loan loan;
  final DocumentReference<Loan> reference;

  @override
  State<_LoanItem> createState() => _LoanItemState();
}

class _LoanItemState extends State<_LoanItem> {
  late Loan loan = widget.loan;
  late DocumentReference<Loan> reference = widget.reference;

  Widget? buildTrailingWidget(LoanStatus status) {
    if (status == LoanStatus.done) return null;
    if (status == LoanStatus.approved) return null;
    // if (status == LoanStatus.approved) return null;
    return PopupMenuButton<LoanStatus>(
      onSelected: (value) async {
        log('Selected Value : $value');
        switch (value) {
          case LoanStatus.pending:
            final shouldApprove = await showConfirmationDialog(
              context,
              'Konfirmasi',
              'Setujui pengajuan peminjaman ini?',
            );
            if (shouldApprove) {
              await reference.update({'status': value.name});
            }

            break;
          case LoanStatus.approved:
            final shouldApprove = await showConfirmationDialog(
              context,
              'Konfirmasi',
              'Setujui pengajuan peminjaman ini?',
            );
            if (shouldApprove) {
              log('Confirm : $status');
              await reference.update({'status': value.name});
              final test = await reference.get();
              log('New Status = ${test.data()?.status}');
            }
            break;

          case LoanStatus.done:
            // TODO: Handle this case.
            break;
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<LoanStatus>> popupItem =
            <PopupMenuEntry<LoanStatus>>[];
        if (status == LoanStatus.done) return popupItem;
        if (status == LoanStatus.approved) return popupItem;

        log('${LoanStatus.values}');

        final newStatus = LoanStatus.values[status.index + 1];
        popupItem.add(PopupMenuItem(
          value: newStatus,
          child: Text(newStatus.name),
        ));

        return popupItem;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      trailing: buildTrailingWidget(loan.status),
      title: FutureBuilder<AuthUser>(
        future: FirebaseCloudStorage().getUserById(userId: loan.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            log('${snapshot.error}');
            return const Text('Nama Peminjam : -');
          }

          final user = snapshot.requireData;
          return Text('Nama Peminjam : ${user.name}');
        },
      ),
      subtitle: Text(
          '${formatDateTime(loan.startTime, 'd-MM-y HH:mm')} s/d ${formatDateTime(loan.endTime, 'd-MM-y HH:mm')}'),
      children: [
        Text('Ruang : ${loan.room?.name}'),
        ...loan.tools
            .map(
              (e) => Text('${e.name} : ${e.quantity} Unit'),
            )
            .toList(),
      ],
    );
  }
}
