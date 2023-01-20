import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

String formatDateTime(DateTime time, String format) {
  return DateFormat(format).format(time);
}

Future<DateTime?> showMyTimePickerDialog(
  BuildContext context,
  DateTime selectedDate,
) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: CustomTimePicker(initialDate: selectedDate),
    ),
  );
}

class CustomTimePicker extends StatefulWidget {
  const CustomTimePicker({
    Key? key,
    this.restorationId,
    required this.initialDate,
  }) : super(key: key);

  final String? restorationId;
  final DateTime initialDate;

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker>
    with RestorationMixin {
  final List<TimeOfDay> _times = const [
    TimeOfDay(hour: 07, minute: 00),
    TimeOfDay(hour: 07, minute: 40),
    TimeOfDay(hour: 08, minute: 20),
    TimeOfDay(hour: 09, minute: 00),
    TimeOfDay(hour: 09, minute: 40),
    TimeOfDay(hour: 10, minute: 20),
    TimeOfDay(hour: 11, minute: 00),
    TimeOfDay(hour: 11, minute: 40),
    TimeOfDay(hour: 12, minute: 20),
    TimeOfDay(hour: 13, minute: 00),
    TimeOfDay(hour: 13, minute: 40),
    TimeOfDay(hour: 14, minute: 20),
    TimeOfDay(hour: 15, minute: 00),
    TimeOfDay(hour: 15, minute: 40),
    TimeOfDay(hour: 16, minute: 20),
    TimeOfDay(hour: 17, minute: 00),
    TimeOfDay(hour: 17, minute: 40),
    TimeOfDay(hour: 18, minute: 20),
    TimeOfDay(hour: 19, minute: 00),
    TimeOfDay(hour: 19, minute: 40),
    TimeOfDay(hour: 20, minute: 20),
    TimeOfDay(hour: 21, minute: 00),
  ];

  RestorableDateTime get selectedDate => _selectedDate;
  late final RestorableDateTime _selectedDate =
      RestorableDateTime(widget.initialDate);
  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.initialDate;
    final dateTimeFromTimeOfDays = _times
        .map((e) => DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, e.hour, e.minute))
        .toList();
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Theme.of(context).backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<DateTime>(
              value: selectedDate,
              items: dateTimeFromTimeOfDays
                  .map((e) => DropdownMenuItem<DateTime>(
                        value: e,
                        child: Text('${e.hour}'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDate.value = value ?? _selectedDate.value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context, _selectedDate.value);
              },
              child: Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  // TODO: implement restorationId
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
  }
}
