import 'package:flutter/material.dart';
import 'package:inventory_app/helpers/api/index.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/helpers/utils/date.dart';

class StockSession {
  final String id;
  final String title;
  final String store;
  final String status;
  final String dateText;
  final int openingSaved;
  final int closingSaved;
  final int totalItems;
  final int totalVariance;
  final bool openingLocked;
  final bool closingLocked;

  const StockSession({
    required this.id,
    required this.title,
    required this.store,
    required this.status,
    required this.dateText,
    required this.openingSaved,
    required this.closingSaved,
    required this.totalItems,
    required this.totalVariance,
    required this.openingLocked,
    required this.closingLocked,
  });

  factory StockSession.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? location =
        json['location'] is Map<String, dynamic> ? json['location'] : null;

    return StockSession(
      id: ApiUtils.readString(json, ['_id']),
      title: ApiUtils.readString(
        json,
        ['name'],
        defaultValue: 'Stock session',
      ),
      store: ApiUtils.readString(
        location,
        ['name'],
        defaultValue: 'Location',
      ),
      status: ApiUtils.readString(
        json,
        ['status'],
        defaultValue: 'open',
      ),
      dateText: formatHumanReadableDateTimeString(
        ApiUtils.readString(json, ['createdAt']),
        fallback: 'Today',
      ),
      openingSaved: ApiUtils.readInt(json, ['totalOpeningSaved']),
      closingSaved: ApiUtils.readInt(json, ['totalClosingSaved']),
      totalItems: ApiUtils.readInt(json, ['totalItems']),
      totalVariance: ApiUtils.readInt(json, ['totalVariance']),
      openingLocked: ApiUtils.readBool(json, 'openingLocked'),
      closingLocked: ApiUtils.readBool(json, 'closingLocked'),
    );
  }

  String get type {
    if (!openingLocked) return 'Opening stock';
    if (!closingLocked) return 'Closing stock';
    return 'Stock count';
  }

  int get itemsSaved {
    if (!openingLocked) return openingSaved;
    return closingSaved;
  }

  String get action => itemsSaved > 0 ? 'Continue' : 'Start';

  double get progress {
    if (totalItems <= 0) return 0;
    return (itemsSaved / totalItems).clamp(0, 1);
  }

  String get routeName {
    if (!openingLocked) {
      return '/opening-stock';
    }

    return '/closing-stock';
  }

  Color get statusColor {
    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus == 'open') {
      return AppColors.success;
    }
    if (normalizedStatus.contains('progress')) return AppColors.appBlue;

    return AppColors.mutedText;
  }
}
