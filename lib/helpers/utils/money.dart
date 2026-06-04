import 'package:intl/intl.dart';

var format = (double val, {int decimal = 2}) {
  final formatCurrency =
      new NumberFormat.simpleCurrency(name: "", decimalDigits: decimal);
  return formatCurrency.format(val);
};
