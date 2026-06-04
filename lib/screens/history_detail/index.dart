import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/helpers/colors.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, Object?> data =
        args is Map<String, Object?> ? args : const {};
    final String title = data['title'] as String? ?? 'Stock Count';
    final String store = data['store'] as String? ?? 'Main Store';
    final String status = data['status'] as String? ?? 'SUBMITTED';
    final String timestamp =
        data['timestamp'] as String? ?? 'Submitted today, 8:14 PM';
    final int items = data['items'] as int? ?? 30;
    final int variances = data['variances'] as int? ?? 0;
    final String? reason = data['reason'] as String?;
    final Color statusColor =
        data['statusColor'] as Color? ?? AppColors.appBlue;

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
                    _DetailSummaryCard(
                      title: title,
                      store: store,
                      status: status,
                      timestamp: timestamp,
                      statusColor: statusColor,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.inventory_2_outlined,
                          value: '$items',
                          label: 'Items counted',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: variances == 0
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          value: '$variances',
                          label: 'Variances',
                          color: variances == 0
                              ? AppColors.success
                              : const Color(0xFFE36C0A),
                        ),
                      ],
                    ),
                    if (reason != null) ...[
                      const SizedBox(height: 18),
                      _ReasonCard(reason: reason),
                    ],
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
                    const _HistoryItemCard(
                      name: 'Tusker Lager 500ml',
                      sku: 'DRK-001',
                      opening: 24,
                      closing: 19,
                      variance: -1,
                      reason: 'Damaged bottle',
                    ),
                    const SizedBox(height: 12),
                    const _HistoryItemCard(
                      name: 'Coca-Cola 500ml',
                      sku: 'SFT-008',
                      opening: 18,
                      closing: 15,
                      variance: 0,
                    ),
                    const SizedBox(height: 12),
                    const _HistoryItemCard(
                      name: 'Chicken Breast',
                      sku: 'KTN-014',
                      opening: 6,
                      closing: 5,
                      variance: 1,
                    ),
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

class _ReasonCard extends StatelessWidget {
  final String reason;

  const _ReasonCard({Key? key, required this.reason}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF9D7A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE36C0A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Review note: $reason',
              style: const TextStyle(
                color: AppColors.darkText,
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

class _HistoryItemCard extends StatelessWidget {
  final String name;
  final String sku;
  final int opening;
  final int closing;
  final int variance;
  final String? reason;

  const _HistoryItemCard({
    Key? key,
    required this.name,
    required this.sku,
    required this.opening,
    required this.closing,
    required this.variance,
    this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  name,
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
            'SKU: $sku',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Quantity(label: 'Opening', value: opening),
              _Quantity(label: 'Closing', value: closing),
              _Quantity(label: 'Variance', value: variance),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Reason: $reason',
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
}

class _Quantity extends StatelessWidget {
  final String label;
  final int value;

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
            '$value',
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
  final int variance;

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
        neutral ? 'No variance' : 'Variance ${positive ? '+' : ''}$variance',
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
}
