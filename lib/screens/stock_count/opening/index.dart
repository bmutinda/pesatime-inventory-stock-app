import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/data/models/stock_session.dart';
import 'package:inventory_app/data/models/stock_session_item.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/stock_sessions/index.dart';

class OpeningStockScreen extends StatefulWidget {
  const OpeningStockScreen({Key? key}) : super(key: key);

  @override
  State<OpeningStockScreen> createState() => _OpeningStockScreenState();
}

class _OpeningStockScreenState extends State<OpeningStockScreen> {
  String? _sessionId;
  StockSession? _session;
  List<_CountItem> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionId != null) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _sessionId = arguments['sessionId'] as String?;
    }

    _loadOpeningStock();
  }

  Future<void> _loadOpeningStock() async {
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

    StockSession? session;
    List<_CountItem> items = const [];
    String? errorMessage;

    try {
      final results = await Future.wait([
        StockSessionService.getSession(sessionId),
        StockSessionService.getSessionItems(sessionId),
      ]);
      session = results[0] as StockSession;
      items = (results[1] as List<StockSessionItem>)
          .map(_CountItem.fromSessionItem)
          .toList();
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
    return message.isEmpty ? 'Unable to load opening stock.' : message;
  }

  @override
  Widget build(BuildContext context) {
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
              const _StockCountHeader(title: 'Opening Stock'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  children: [
                    if (_isLoading)
                      const _LoadingState()
                    else if (_errorMessage != null)
                      _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadOpeningStock,
                      )
                    else if (_session == null)
                      const _EmptyState(message: 'Stock session not found.')
                    else ...[
                      _SessionSummaryCard(
                        session: _session!,
                        savedCount: _items.where((item) => item.saved).length,
                        itemCount: _items.length,
                      ),
                      const SizedBox(height: 16),
                      const _InfoNotice(),
                      const SizedBox(height: 16),
                      const _SearchField(),
                      const SizedBox(height: 14),
                      if (_items.isEmpty)
                        const _EmptyState(
                          message: 'No items found for this stock session.',
                        )
                      else
                        for (int index = 0; index < _items.length; index++) ...[
                          _CountItemCard(
                            item: _items[index],
                            isOpening: true,
                            onDecrease: () => _changeQuantity(index, -1),
                            onIncrease: () => _changeQuantity(index, 1),
                            onSave: () => _saveItem(index),
                            onReasonSelected: (_) {},
                          ),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _CountBottomBar(
          isOpening: true,
          savedCount: _items.where((item) => item.saved).length,
          onPrimaryPressed: _submitOpeningStock,
        ),
      ),
    );
  }

  void _submitOpeningStock() {
    final session = _session;
    if (session == null) return;

    Navigator.of(context).pushNamed(
      '/submission-success',
      arguments: {
        'countType': 'Opening stock',
        'title': 'Opening stock submitted',
        'store': session.store,
        'items': _items.length,
        'variances': 0,
      },
    );
  }

  void _changeQuantity(int index, int change) {
    setState(() {
      final int nextValue = _items[index].quantity + change;
      _items[index].quantity = nextValue < 0 ? 0 : nextValue;
      _items[index].saved = false;
    });
  }

  Future<void> _saveItem(int index) async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    try {
      await StockSessionService.submitOpeningQty(
        sessionId: sessionId,
        lineId: _items[index].lineId,
        openingQty: _items[index].quantity.toDouble(),
      );

      if (!mounted) return;
      setState(() {
        _items[index].saved = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_readErrorMessage(error)),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
    }
  }
}

class _StockCountHeader extends StatelessWidget {
  final String title;

  const _StockCountHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF3FF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7DCFF)),
        ),
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
          IconButton(
            onPressed: () => _showSessionOptions(context),
            icon: const Icon(Icons.more_vert, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  void _showSessionOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session options',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.info_outline,
                  title: 'Session details',
                  subtitle: 'Today, Jun 4',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _OptionTile(
                  icon: Icons.close,
                  title: 'Close options',
                  subtitle: 'Return to stock count',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.appBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  final StockSession session;
  final int savedCount;
  final int itemCount;

  const _SessionSummaryCard({
    Key? key,
    required this.session,
    required this.savedCount,
    required this.itemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int totalItems =
        session.totalItems > 0 ? session.totalItems : itemCount;
    final double progress =
        totalItems <= 0 ? 0 : (savedCount / totalItems).clamp(0, 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      icon: Icons.location_on_outlined,
                      text: session.store,
                    ),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.calendar_today_outlined,
                      text: session.dateText,
                    ),
                  ],
                ),
              ),
              const _OpenBadge(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$savedCount',
                      style: const TextStyle(
                        color: AppColors.appBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: ' of $totalItems counted'),
                  ],
                ),
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.appBlue,
              backgroundColor: const Color(0xFFE4E8EF),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF9FC3FF)),
      ),
      child: const Text(
        'OPEN',
        style: TextStyle(
          color: AppColors.appBlue,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.appBlue, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Enter opening quantity and save each item.',
            style: TextStyle(
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

class _SearchField extends StatelessWidget {
  const _SearchField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search items',
        hintStyle: const TextStyle(
          color: AppColors.inputIcon,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.mutedText, size: 24),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.appBlue, width: 1.4),
        ),
      ),
    );
  }
}

class _CountItemCard extends StatelessWidget {
  final _CountItem item;
  final bool isOpening;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSave;
  final ValueChanged<String> onReasonSelected;

  const _CountItemCard({
    Key? key,
    required this.item,
    required this.isOpening,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSave,
    required this.onReasonSelected,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(height: 4),
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
              if (!isOpening) _VarianceBadge(variance: item.variance),
            ],
          ),
          if (!isOpening) ...[
            const SizedBox(height: 12),
            Text(
              'Expected  ${item.expected}    |    Opening  ${item.opening}',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            isOpening ? 'Opening qty' : 'Closing qty',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _QuantityStepper(
                value: item.quantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              ),
              const Spacer(),
              _SaveButton(onPressed: onSave),
            ],
          ),
          if (item.saved) ...[
            const SizedBox(height: 14),
            const _SavedLabel(),
          ],
          if (!isOpening && item.variance != 0) ...[
            const SizedBox(height: 14),
            _ReasonSelector(
              value: item.reason,
              onSelected: onReasonSelected,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    Key? key,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD0D7E2)),
      ),
      child: Row(
        children: [
          _StepperButton(icon: Icons.remove, onPressed: onDecrease),
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onPressed: onIncrease),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({Key? key, required this.icon, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: double.infinity,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.darkText, size: 22),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SaveButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.appBlue,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppColors.appBlue, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: const Text(
          'Save',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SavedLabel extends StatelessWidget {
  const _SavedLabel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.check_circle, color: AppColors.success, size: 20),
        SizedBox(width: 8),
        Text(
          'Saved',
          style: TextStyle(
            color: Color(0xFF079455),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

class _ReasonSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onSelected;

  const _ReasonSelector({
    Key? key,
    this.value,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showReasonSheet(context),
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFD0D7E2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Add reason',
                    style: TextStyle(
                      color: value == null
                          ? AppColors.inputIcon
                          : AppColors.darkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReasonSheet(BuildContext context) {
    const List<String> reasons = [
      'Damaged bottle',
      'Spillage',
      'Staff meal',
      'Supplier return',
      'Wrong opening count',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Variance reason',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select why the closing count differs.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                for (final reason in reasons)
                  ListTile(
                    onTap: () {
                      onSelected(reason);
                      Navigator.of(context).pop();
                    },
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reason,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: value == reason
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountBottomBar extends StatelessWidget {
  final bool isOpening;
  final int savedCount;
  final VoidCallback onPrimaryPressed;

  const _CountBottomBar({
    Key? key,
    required this.isOpening,
    required this.savedCount,
    required this.onPrimaryPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD9E2F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (!isOpening) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.appBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ],
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$savedCount',
                        style: const TextStyle(
                          color: AppColors.appBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: '/30 saved'),
                    ],
                  ),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      isOpening ? Icons.check_circle : Icons.error_outline,
                      color:
                          isOpening ? AppColors.success : AppColors.mutedText,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpening ? 'Ready to submit' : 'Reasons required',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isOpening ? 'Submit opening counts' : 'Review closing',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!isOpening) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

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

class _CountItem {
  final String lineId;
  final String name;
  final String sku;
  int quantity;
  bool saved;
  final int expected;
  final int opening;
  int variance;
  String? reason;

  _CountItem({
    required this.lineId,
    required this.name,
    required this.sku,
    required this.quantity,
    this.saved = false,
    this.expected = 0,
    this.opening = 0,
    this.variance = 0,
    this.reason,
  });

  factory _CountItem.fromSessionItem(StockSessionItem item) {
    return _CountItem(
      lineId: item.id,
      name: item.name,
      sku: item.sku,
      quantity: item.openingQty.round(),
      saved: item.openingQty > 0,
    );
  }

  _CountItem copy() {
    return _CountItem(
      lineId: lineId,
      name: name,
      sku: sku,
      quantity: quantity,
      saved: saved,
      expected: expected,
      opening: opening,
      variance: variance,
      reason: reason,
    );
  }
}
