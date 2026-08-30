import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('ru');
final _date = DateFormat('d MMM yyyy, HH:mm', 'ru');

String rub(int value) => '${_money.format(value)} ₽';

String compact(int value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)} млрд ₽';
  }
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)} млн ₽';
  }
  return rub(value);
}

String formatDate(DateTime value) => _date.format(value);
