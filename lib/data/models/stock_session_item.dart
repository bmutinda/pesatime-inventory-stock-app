import 'package:inventory_app/helpers/api/index.dart';

class StockSessionItem {
  final String id;
  final String itemId;
  final String name;
  final String sku;
  final double openingQty;
  final double closingQty;
  final double varianceQty;
  final String varianceReason;

  const StockSessionItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.sku,
    required this.openingQty,
    required this.closingQty,
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
      closingQty: ApiUtils.readDouble(json, ['closingQty']),
      varianceQty: ApiUtils.readDouble(json, ['varianceQty']),
      varianceReason: ApiUtils.readString(json, ['varianceReason']),
    );
  }
}
