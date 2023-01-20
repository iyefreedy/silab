import 'dart:collection';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/enums/loan_status.dart';
import 'package:silab/enums/menu_action.dart';
import 'package:silab/services/auth/bloc/auth_bloc.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/utilities/dialogs/dialogs.dart';
import 'package:silab/utilities/utils.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/cloud/loan.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int currentIndex = 0;
  final List<Widget> _tabs = const [
    _AdminDashboard(),
    _Admin(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('SILab - Admin'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);

                  if (!mounted) {
                    return;
                  }
                  if (shouldLogout) {
                    context.read<AuthBloc>().add(AuthEventLogout());
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: MenuAction.logout,
                  child: Text('Logout'),
                )
              ];
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
      body: _tabs.elementAt(currentIndex),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({Key? key}) : super(key: key);

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

class _Admin extends StatefulWidget {
  const _Admin({
    Key? key,
  }) : super(key: key);

  @override
  State<_Admin> createState() => _AdminState();
}

class _AdminState extends State<_Admin> {
  String? mToken = " ";

  void getToken() async {
    FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        mToken = value;
      });
      log('$mToken');
    });
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Data Ruangan'),
          leading: const Icon(Icons.room),
          onTap: () => Navigator.of(context).pushNamed(adminRoomsRoute),
        ),
        ListTile(
          title: const Text('Data Peminjaman'),
          leading: const Icon(Icons.history),
          onTap: () => Navigator.of(context).pushNamed(adminLoansRoute),
        ),
        // ListTile(
        //   title: const Text('Data Pengguna'),
        //   leading: const Icon(Icons.person),
        //   onTap: () => Navigator.of(context).pushNamed(adminUsersRoute),
        // ),
        ListTile(
          title: const Text('Laporan Peminjaman'),
          leading: const Icon(Icons.event),
          onTap: () => Navigator.of(context).pushNamed(adminLoanReportRoute),
        ),
        ListTile(
          title: const Text('Laporan Data Ruangan'),
          leading: const Icon(Icons.meeting_room),
          onTap: () => Navigator.of(context).pushNamed(adminRoomReportRoute),
        ),
        ListTile(
          title: const Text('Laporan Data Alat'),
          leading: const Icon(Icons.tv),
          onTap: () => Navigator.of(context).pushNamed(adminToolReportRoute),
        ),
        ListTile(
          title: const Text('Laporan Data Kerusakan Alat'),
          leading: const Icon(Icons.tv_off),
          onTap: () =>
              Navigator.of(context).pushNamed(adminDamagedToolReportRoute),
        ),
      ],
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
                          onTap: () {
                            showLoanDialog(context, value[index]);
                          },
                          title: Text(
                              '${formatDateTime(value[index].startTime, 'd-MM-y HH:mm')} s/d ${formatDateTime(value[index].endTime, 'HH:mm')}'),
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
      ],
    );
  }
}
