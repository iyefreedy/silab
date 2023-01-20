import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../services/auth/auth_service.dart';
import '../services/cloud/firebase_cloud_storage.dart';
import '../services/cloud/room.dart';
import '../services/cloud/tool.dart';
import '../utilities/dialogs/dialogs.dart';
import '../utilities/formatter/limit_number_format.dart';

class CreateLoanPage extends StatelessWidget {
  const CreateLoanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.getArgument<DateTime>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Peminjaman'),
      ),
      body: _LoanForm(
        selectedDate: selectedDate,
      ),
    );
  }
}

class _LoanForm extends StatefulWidget {
  const _LoanForm({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  final DateTime selectedDate;

  @override
  State<_LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<_LoanForm> {
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late FirebaseCloudStorage _cloudStorage;

  String? _roomId;
  DateTime? _startTime;
  DateTime? _endTime;

  Map<String, Room> _rooms = {};
  List<Tool> _tools = [];
  List<TextEditingController> _toolControllers = [];

  void _onPressedSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final user = AuthService.firebase().currentUser!;

      await _cloudStorage.addLoan(
        userId: user.id,
        room: _rooms[_roomId],
        tools: _tools,
        startTime: _startTime,
        endTime: _endTime,
      );

      if (!mounted) return;
      await showMessageDialog(
        context,
        'Pengajuan berhasil disimpan',
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      log('Submitted');
    } on Exception catch (e) {
      await showErrorDialog(context, 'Error : $e');
    }
  }

  void _onChangeDropdownRoom(String? value) async {
    setState(() {
      _roomId = value;
    });

    final tools = await _cloudStorage.fetchAvailableTools(_roomId);
    setState(() {
      _tools = tools;
      _toolControllers = tools.map((e) => TextEditingController()).toList();
    });
  }

  void _onTapEndTimeField() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 07, minute: 00),
    );

    if (selectedTime == null) return;

    setState(() {
      _endTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });

    _endTimeController.text = DateFormat('HH:mm').format(_endTime!);
  }

  void _onTapStartTimeField() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 07, minute: 00),
    );

    if (selectedTime == null) return;

    setState(() {
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });

    _startTimeController.text = DateFormat('HH:mm').format(_startTime!);
  }

  @override
  void initState() {
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _cloudStorage = FirebaseCloudStorage();
    initSelection();
    super.initState();
  }

  void initSelection() async {
    final rooms = await _cloudStorage.fetchAvailableRoom();
    setState(() {
      _rooms = rooms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          loanDateText,
          startTimeFormField,
          endTimeFormField,
          dropdownRoom,
          const SizedBox(height: 20.0),
          const Text('Pilih Alat'),
          const SizedBox(height: 12.0),
          if (_tools.isNotEmpty)
            for (var i = 0; i < _tools.length; i++)
              TextField(
                controller: _toolControllers[i],
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _tools[i] = _tools[i].copyWith(quantity: int.parse(value));
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LimitNumberFormat(min: 0, max: _tools[i].quantity),
                ],
                decoration: InputDecoration(
                  // hintText: 'Maksimal unit : ${_tools[i].quantity}',
                  label: Text(
                      '${_tools[i].name} (Tersedia ${_tools[i].quantity} unit)'),
                ),
              ),
          const SizedBox(height: 10.0),
          ElevatedButton(
            onPressed: _startTime == null || _endTime == null
                ? null
                : _onPressedSubmit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Text get loanDateText {
    return Text(
      'Tanggal Peminjaman : ${DateFormat('dd-MM-yyyy').format(widget.selectedDate)}',
      style: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  List<DropdownMenuItem<String>>? get dropdownRoomItem {
    return _rooms.entries
        .map((e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value.name),
            ))
        .toList();
  }

  DropdownButton<String> get dropdownRoom {
    return DropdownButton<String>(
      value: _roomId,
      hint: const Text('Pilih ruangan'),
      items: dropdownRoomItem,
      onChanged: _onChangeDropdownRoom,
    );
  }

  TextFormField get endTimeFormField {
    return TextFormField(
      keyboardType: TextInputType.none,
      controller: _endTimeController,
      decoration: const InputDecoration(hintText: 'Jam Selesai'),
      onTap: _onTapEndTimeField,
    );
  }

  TextFormField get startTimeFormField {
    return TextFormField(
      keyboardType: TextInputType.none,
      controller: _startTimeController,
      decoration: const InputDecoration(hintText: 'Jam Mulai'),
      onTap: _onTapStartTimeField,
    );
  }
}
