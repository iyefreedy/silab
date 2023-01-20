import 'package:intl/intl.dart';

extension on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension IdFormat on DateFormat {
  static DateFormat ddMMMMyyyy([dynamic locale]) {
    return DateFormat('dd MMMM yy', locale);
  }
}
