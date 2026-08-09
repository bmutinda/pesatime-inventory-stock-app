import 'package:inventory_app/helpers/api/index.dart';

class StockSessionItem {
  final String id;
  final String itemId;
  final String name;
  final String sku;
  final double openingQty;
  final double openingBalance;
  final bool openingCounted;
  final double openingVariance;
  final String openingVarianceReason;
  final double closingQty;
  final bool closingCounted;
  final double expectedClosingQty;
  final double varianceQty;
  final String varianceReason;

  const StockSessionItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.sku,
    required this.openingQty,
    required this.openingBalance,
    required this.openingCounted,
    required this.openingVariance,
    required this.openingVarianceReason,
    required this.closingQty,
    required this.closingCounted,
    required this.expectedClosingQty,
    required this.varianceQty,
    required this.varianceReason,
  });

  factory StockSessionItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'];

    return StockSessionItem(
      id: ApiUtils.readString(json, ['_id']),
      itemId: ApiUtils.readString(item, ['_id']),
      name: ApiUtils.readString(item, ['name'], defaultValue: 'Item'),
      sku: ApiUtils.readString(item, ['sku'], defaultValue: '-'),
      openingQty: ApiUtils.readDouble(json, ['openingQty']),
      openingBalance: ApiUtils.readDouble(json, ['openingBalance']),
      openingCounted: ApiUtils.readBool(json, 'openingCounted'),
      openingVariance: ApiUtils.readDouble(json, ['openingVariance']),
      openingVarianceReason:
          ApiUtils.readString(json, ['openingVarianceReason']),
      closingQty: ApiUtils.readDouble(json, ['closingQty']),
      closingCounted: ApiUtils.readBool(json, 'closingCounted'),
      expectedClosingQty: ApiUtils.readDouble(json, ['expectedClosingQty']),
      varianceQty: ApiUtils.readDouble(json, ['varianceQty']),
      varianceReason: ApiUtils.readString(json, ['varianceReason']),
    );
  }
}
