import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.currency(symbol: 'GHS ');
final dateFormatter = DateFormat('yyyy-MM-dd');
final dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');

String money(num value) => currencyFormatter.format(value);

List<String> parseLottoNumbers(String input) {
  return input
      .split(RegExp(r'[-,\s]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String normalizePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0') && digits.length == 10) {
    return '233${digits.substring(1)}';
  }
  return digits;
}
