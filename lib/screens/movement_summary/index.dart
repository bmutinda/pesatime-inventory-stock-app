import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/data/models/stock_movement_summary.dart';
import 'package:inventory_app/data/models/stock_session_item.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/stock_sessions/index.dart';

class MovementSummaryScreen extends StatefulWidget {
  const MovementSummaryScreen({Key? key}) : super(key: key);

  @override
  State<MovementSummaryScreen> createState() => _MovementSummaryScreenState();
}

class _MovementSummaryScreenState extends State<MovementSummaryScreen> {
  bool _initialized = false;
  bool _isLoading = true;
  String? _sessionId;
  StockSessionItem? _item;
  StockMovementSummary? _summary;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _sessionId = arguments['sessionId'] as String?;
      final item = arguments['item'];
      if (item is StockSessionItem) _item = item;
    }

    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final sessionId = _sessionId;
    final item = _item;
    if (sessionId == null || sessionId.isEmpty || item == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Movement summary is unavailable.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await StockSessionService.getMovementSummary(
        sessionId: sessionId,
        lineId: item.id,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _isLoading = false;
        _errorMessage =
            message.isEmpty ? 'Unable to load movement summary.' : message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0055C8),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: Column(
            children: [
              const _MovementHeader(title: 'Movements Summary'),
              Expanded(
                child: item == null
                    ? _ErrorState(
                        message:
                            _errorMessage ?? 'Movement summary is unavailable.',
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _ItemHeader(item: item),
                          const SizedBox(height: 18),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.appBlue,
                                ),
                              ),
                            )
                          else if (_errorMessage != null)
                            _ErrorState(
                              message: _errorMessage!,
                              onRetry: _loadSummary,
                            )
                          else if (_summary != null) ...[
                            _MovementTotalCard(
                              icon: Icons.south_west_rounded,
                              label: 'Total In',
                              value: _summary!.totalStockIn,
                              color: const Color(0xFF079455),
                              backgroundColor: const Color(0xFFEAF8F0),
                            ),
                            const SizedBox(height: 12),
                            _MovementTotalCard(
                              icon: Icons.north_east_rounded,
                              label: 'Total Out',
                              value: _summary!.totalStockOut,
                              color: const Color(0xFFE11D48),
                              backgroundColor: const Color(0xFFFDECEF),
                            ),
                            const SizedBox(height: 12),
                            _MovementTotalCard(
                              icon: Icons.tune_rounded,
                              label: 'Total Adjustments',
                              value: _summary!.totalAdjustments,
                              color: const Color(0xFF6941C6),
                              backgroundColor: const Color(0xFFF2EEFF),
                              showSign: true,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE11D48),
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MovementHeader extends StatelessWidget {
  final String title;

  const _MovementHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF3FF),
        border: Border(bottom: BorderSide(color: Color(0xFFC7DCFF))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  final StockSessionItem item;

  const _ItemHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E0EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.appBlue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SKU: ${item.sku}',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTotalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final Color backgroundColor;
  final bool showSign;

  const _MovementTotalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatQuantity(value, showSign: showSign),
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatQuantity(double value, {bool showSign = false}) {
  final rounded = double.parse(value.toStringAsFixed(2));
  final fixed = rounded.toStringAsFixed(2);
  final formatted = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return showSign && value > 0 ? '+$formatted' : formatted;
}
