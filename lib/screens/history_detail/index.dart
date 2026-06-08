import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/data/models/stock_session.dart';
import 'package:inventory_app/data/models/stock_session_item.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/stock_sessions/index.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({Key? key}) : super(key: key);

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  String? _sessionId;
  StockSession? _session;
  List<StockSessionItem> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is StockSession) {
      _session = args;
      _sessionId = args.id;
    } else if (args is String) {
      _sessionId = args;
    } else if (args is Map<String, dynamic>) {
      _sessionId = args['sessionId'] as String?;
    }

    _loadHistoryDetail();
  }

  Future<void> _loadHistoryDetail() async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to identify stock session.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    StockSession? session = _session;
    List<StockSessionItem> items = const [];
    String? errorMessage;

    try {
      final results = await Future.wait([
        StockSessionService.getSession(sessionId),
        StockSessionService.getSessionItems(sessionId),
      ]);
      session = results[0] as StockSession;
      items = results[1] as List<StockSessionItem>;
    } catch (error) {
      errorMessage = _readErrorMessage(error);
    }

    if (!mounted) return;
    setState(() {
      _session = session;
      _items = items;
      _errorMessage = errorMessage;
      _isLoading = false;
    });
  }

  String _readErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Unable to load history detail.' : message;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final itemCount = _items.length;
    final varianceCount = _items.where((item) => item.varianceQty != 0).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0055C8),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const _DetailHeader(title: 'History Detail'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  children: [
                    if (_isLoading)
                      const _LoadingState()
                    else if (_errorMessage != null)
                      _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadHistoryDetail,
                      )
                    else if (session == null)
                      const _EmptyState(message: 'Stock session not found.')
                    else ...[
                      _DetailSummaryCard(
                        title: session.title,
                        store: session.store,
                        status: session.status,
                        timestamp: session.dateText,
                        statusColor: session.statusColor,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.inventory_2_outlined,
                            value: '$itemCount',
                            label: 'Items counted',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: varianceCount == 0
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined,
                            value: '$varianceCount',
                            label: 'Variances',
                            color: varianceCount == 0
                                ? AppColors.success
                                : const Color(0xFFE36C0A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Submitted items',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const _EmptyState(
                          message: 'No items found for this stock session.',
                        )
                      else
                        for (final item in _items) ...[
                          _HistoryItemCard(item: item),
                          const SizedBox(height: 12),
                        ],
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

class _DetailHeader extends StatelessWidget {
  final String title;

  const _DetailHeader({Key? key, required this.title}) : super(key: key);

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

class _DetailSummaryCard extends StatelessWidget {
  final String title;
  final String store;
  final String status;
  final String timestamp;
  final Color statusColor;

  const _DetailSummaryCard({
    Key? key,
    required this.title,
    required this.store,
    required this.status,
    required this.timestamp,
    required this.statusColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0D7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(text: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          _MetaLine(icon: Icons.location_on_outlined, text: store),
          const SizedBox(height: 8),
          _MetaLine(icon: Icons.access_time, text: timestamp),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.appBlue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8DEE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final StockSessionItem item;

  const _HistoryItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final variance = item.varianceQty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _VarianceBadge(variance: variance),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SKU: ${item.sku}',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Quantity(label: 'Opening', value: _formatQty(item.openingQty)),
              _Quantity(label: 'Closing', value: _formatQty(item.closingQty)),
              _Quantity(label: 'Variance', value: _formatQty(variance)),
            ],
          ),
          if (variance != 0 && item.varianceReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Reason: ${item.varianceReason}',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.appBlue),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.appBlue,
                side: const BorderSide(color: AppColors.appBlue, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Quantity extends StatelessWidget {
  final String label;
  final String value;

  const _Quantity({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedText, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({Key? key, required this.text, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VarianceBadge extends StatelessWidget {
  final double variance;

  const _VarianceBadge({Key? key, required this.variance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool positive = variance > 0;
    final bool neutral = variance == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: neutral
            ? const Color(0xFFEAF8F0)
            : positive
                ? const Color(0xFFFFF3E6)
                : const Color(0xFFFDECEF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        neutral
            ? 'No variance'
            : 'Variance ${positive ? '+' : ''}${_formatQty(variance)}',
        style: TextStyle(
          color: neutral
              ? const Color(0xFF079455)
              : positive
                  ? const Color(0xFFE36C0A)
                  : const Color(0xFFE11D48),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
  }
}
