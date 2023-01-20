import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LimitNumberFormat extends TextInputFormatter {
  final int min;
  final int max;

  LimitNumberFormat({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var value = int.tryParse(newValue.text) ?? 0;
    if (value < min) {
      return TextEditingValue(text: min.toString());
    } else if (value > max) {
      return TextEditingValue(text: max.toString());
    }
    return newValue;
  }
}
