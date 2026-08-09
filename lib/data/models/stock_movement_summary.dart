import 'package:inventory_app/helpers/api/index.dart';

class StockMovementSummary {
  final double totalStockIn;
  final double totalStockOut;
  final double totalAdjustments;

  const StockMovementSummary({
    required this.totalStockIn,
    required this.totalStockOut,
    required this.totalAdjustments,
  });

  factory StockMovementSummary.fromJson(Map<String, dynamic> json) {
    return StockMovementSummary(
      totalStockIn: ApiUtils.readDouble(json, ['totalStockIn']),
      totalStockOut: ApiUtils.readDouble(json, ['totalStockOut']),
      totalAdjustments: ApiUtils.readDouble(json, ['totalAdjustments']),
    );
  }
}
