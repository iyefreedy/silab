import 'dart:collection';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:silab/enums/loan_status.dart';
import 'package:silab/extensions/datetime/compare_date.dart';
import 'package:silab/services/auth/auth_service.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/auth/bloc/auth_bloc.dart';
import 'package:silab/utilities/dialogs/dialogs.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/route_constants.dart';
import '../../services/cloud/firebase_cloud_storage.dart';
import '../../services/cloud/loan.dart';
import '../../services/cloud/room.dart';
import '../../utilities/utils.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int currentIndex = 0;

  final List<Widget> _tabs = const [
    _UserDashboardView(),
    _RoomsView(),
    _UserLoanView(),
    _BiodataView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SILab - User'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: const Text('Logout'),
                  onTap: () {
                    context.read<AuthBloc>().add(AuthEventLogout());
                  },
                )
              ];
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Lihat Ruangan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Peminjaman Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Biodata',
          ),
        ],
      ),
      body: _tabs.elementAt(currentIndex),
    );
  }
}

class _UserDashboardView extends StatelessWidget {
  const _UserDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Loan>>(
      stream: FirebaseCloudStorage()
          .loansCollection
          .where('status', isNotEqualTo: LoanStatus.pending.name)
          .snapshots(),
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
        return _LoanCalendar(
          references: loans.docs.map((e) => e.reference).toList(),
          loans: loans.docs.map((e) => e.data()).toList(),
        );
      },
    );
  }
}

class _LoanCalendar extends StatefulWidget {
  const _LoanCalendar({
    Key? key,
    required this.references,
    required this.loans,
  }) : super(key: key);

  final List<DocumentReference<Loan>> references;
  final List<Loan> loans;

  @override
  State<_LoanCalendar> createState() => __LoanCalendarState();
}

class __LoanCalendarState extends State<_LoanCalendar> {
  late final ValueNotifier<List<Loan>> _selectedEvents;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  @override
  void initState() {
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getLoansForDay(_selectedDay!));
    super.initState();
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  List<Loan> _getLoansForDay(DateTime? date) {
    final loans = widget.loans;
    final loansSources = {
      for (var element in loans)
        element.startTime: loans
            .where((e) => isSameDay(e.startTime, element.startTime))
            .toList()
    };
    final loansLinked = LinkedHashMap<DateTime, List<Loan>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(loansSources);
    return loansLinked[date] ?? <Loan>[];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jadwal Peminjaman Alat dan Ruangan',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            TableCalendar<Loan>(
              focusedDay: _focusedDay,
              eventLoader: _getLoansForDay,
              holidayPredicate: (day) {
                return day.weekday == DateTime.saturday ||
                    day.weekday == DateTime.sunday;
              },
              firstDay: DateTime(1970),
              lastDay: DateTime(2030),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeSelectionMode: _rangeSelectionMode,
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _selectedDay = null;
                  _focusedDay = focusedDay;
                  _rangeStart = start;
                  _rangeEnd = end;
                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _rangeSelectionMode = RangeSelectionMode.toggledOff;
                  });
                  _selectedEvents.value = _getLoansForDay(selectedDay);
                }
              },
            ),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Data Peminjaman',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<Loan>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () async => await showLoanDialog(
                            context,
                            value[index],
                          ),
                          title: Text(
                            formatDateTime(
                                value[index].startTime, 'd-MM-y HH:mm'),
                          ),
                          subtitle: Text('${value[index].room?.name}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 5,
          right: 5,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(createLoanRoute, arguments: _selectedDay);
            },
            child: const Icon(Icons.add),
          ),
        )
      ],
    );
  }
}

class _RoomsView extends StatelessWidget {
  const _RoomsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Room>>(
      stream: FirebaseCloudStorage().allRooms(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return ListView.builder(
            itemCount: 20,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: ListTile(
                  tileColor: Colors.grey.shade300,
                ),
              );
            },
          );
        }

        final rooms = snapshot.requireData;
        return ListView.builder(
          itemCount: rooms.size,
          itemBuilder: (context, index) {
            return _RoomItem(
              room: rooms.docs[index].data(),
              reference: rooms.docs[index].reference,
            );
          },
        );
      },
    );
  }
}

class _RoomItem extends StatelessWidget {
  const _RoomItem({
    Key? key,
    required this.room,
    required this.reference,
  }) : super(key: key);

  final DocumentReference<Room> reference;
  final Room room;
  @override
  Widget build(BuildContext context) {
    log('message');
    return ListTile(
      // trailing: _buildPopupMenuButton(context),
      onTap: () =>
          Navigator.of(context).pushNamed(toolsRoute, arguments: reference),
      title: Text(room.name),
      subtitle: Text(room.description),
      leading: Image.network(room.image),
    );
  }
}

class _UserLoanView extends StatelessWidget {
  const _UserLoanView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: LoanStatus.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Peminjaman Saya'),
          bottom: TabBar(
            tabs: LoanStatus.values.map((e) => Tab(text: e.name)).toList(),
          ),
        ),
        body: TabBarView(
          children: LoanStatus.values
              .map(
                (e) => StreamBuilder<QuerySnapshot<Loan>>(
                  stream: FirebaseCloudStorage().userLoan(
                    userId: AuthService.firebase().currentUser!.id,
                    status: e.name,
                  ),
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

                    if (loans.docs.isEmpty) {
                      return const Center(
                        child: Text('Belum ada data peminjaman'),
                      );
                    }
                    return _UserLoanList(loans: loans);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _UserLoanList extends StatefulWidget {
  const _UserLoanList({
    Key? key,
    required this.loans,
  }) : super(key: key);

  final QuerySnapshot<Loan> loans;

  @override
  State<_UserLoanList> createState() => _UserLoanListState();
}

class _UserLoanListState extends State<_UserLoanList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.loans.size,
      itemBuilder: (cotext, index) {
        final loan = widget.loans.docs[index].data();
        return ExpansionTile(
          trailing: loan.status == LoanStatus.approved
              ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    final ctx = context;
                    final shouldDone = await showConfirmationDialog(
                      context,
                      'Konfirmasi',
                      'Apakah anda yakin ingin mengembalikan peminjaman ini',
                    );

                    if (shouldDone) {
                      // await widget.loans.docs[index].reference.update({
                      //   'status': 'Selesai',
                      // }).then((value) async {

                      // });
                      // ignore: use_build_context_synchronously
                      // await showMessageDialog(
                      //   context,
                      //   'Berhasil mengembalikan peminjaman',
                      // );

                      await showErrorDialog(context,
                          'Tidak bisa mengembalikan peminjaman ketika waktu peminjaman belum selesai');
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'done',
                      child: Text('Tandai sudah selesai'),
                    ),
                  ],
                )
              : null,
          subtitle: Text.rich(
            TextSpan(
              text: '${DateFormat('dd-MM-yyyy').format(loan.startTime)} ',
              children: [
                TextSpan(
                    text: '${DateFormat('HH:mm').format(loan.startTime)} - '),
                TextSpan(text: '${DateFormat('HH:mm').format(loan.endTime)} ')
              ],
            ),
          ),
          title: const Text('Tanggal Peminjaman'),
          children: [
            ListTile(
              title: const Text('Ruang'),
              subtitle: Text('${loan.room?.name}'),
            ),
            ListTile(
              title: const Text('Alat'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: loan.tools
                    .map((e) => Text(
                          '- ${e.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ))
                    .toList(),
              ),
            ),
            ListTile(
              title: const Text('Tanggal Pengajuan'),
              subtitle: Text(
                DateFormat('dd-MM-yyyy HH:mm').format(loan.createdAt),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BiodataView extends StatelessWidget {
  const _BiodataView();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser>(
      future: FirebaseCloudStorage()
          .getUserById(userId: AuthService.firebase().currentUser!.id),
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

        final user = snapshot.requireData;
        return ListView(
          children: [
            ListTile(
              title: const Text('Nama Lengkap'),
              subtitle: Text('${user.name}'),
            ),
            ListTile(
              title: const Text('Role'),
              subtitle: Text('${user.role}'),
            ),
            ListTile(
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),
            ListTile(
              title: const Text('Fakultas'),
              subtitle: Text(user.faculty ?? '-'),
            ),
            ListTile(
              title: const Text('Program Studi'),
              subtitle: Text(user.vocation ?? '-'),
            ),
            ListTile(
              title: const Text('Tanggal Lahir'),
              subtitle: user.birthDate != null
                  ? Text(IdFormat.ddMMMMyyyy('id').format(user.birthDate!))
                  : const Text('-'),
            ),
          ],
        );
      },
    );
  }
}
