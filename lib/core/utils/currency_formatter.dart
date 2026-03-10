import 'package:intl/intl.dart';

String formatNpr(num amount) {
  final normalized = amount.toDouble();
  return 'NPR ${NumberFormat('#,##0.00').format(normalized)}';
}
