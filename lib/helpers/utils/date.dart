import 'dart:ui';

import 'package:intl/intl.dart';

String formatHumanReadableDate(
  DateTime date, {
  String? locale,
  String pattern = 'MMM d, y',
}) {
  final localDate = date.toLocal();
  final resolvedLocale =
      locale ?? PlatformDispatcher.instance.locale.toString();
  return DateFormat(pattern, resolvedLocale).format(localDate);
}

String formatHumanReadableDateString(
  String value, {
  String? locale,
  String pattern = 'MMM d, y',
  String fallback = '',
}) {
  final date = DateTime.tryParse(value);
  if (date == null) return fallback;

  return formatHumanReadableDate(
    date,
    locale: locale,
    pattern: pattern,
  );
}

String formatHumanReadableDateTime(
  DateTime date, {
  String? locale,
  String pattern = 'MMM d, y, h:mm a',
}) {
  final localDate = date.toLocal();
  final resolvedLocale =
      locale ?? PlatformDispatcher.instance.locale.toString();
  return DateFormat(pattern, resolvedLocale).format(localDate);
}

String formatHumanReadableDateTimeString(
  String value, {
  String? locale,
  String pattern = 'MMM d, y, h:mm a',
  String fallback = '',
}) {
  final date = DateTime.tryParse(value);
  if (date == null) return fallback;

  return formatHumanReadableDateTime(
    date,
    locale: locale,
    pattern: pattern,
  );
}
