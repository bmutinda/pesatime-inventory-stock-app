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
  bool _isSubmitting = false;
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

  String _readErrorMessage(
    Object error, {
    String fallback = 'Unable to load opening stock.',
  }) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
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
                      if (_items.isEmpty)
                        const _EmptyState(
                          message: 'No items found for this stock session.',
                        )
                      else
                        for (int index = 0; index < _items.length; index++) ...[
                          _CountItemCard(
                            item: _items[index],
                            onDecrease: () => _changeQuantity(index, -1),
                            onIncrease: () => _changeQuantity(index, 1),
                            onSave: () => _saveItem(index),
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
          savedCount: _items.where((item) => item.saved).length,
          itemCount: _items.length,
          isSubmitting: _isSubmitting,
          onPrimaryPressed: _submitOpeningStock,
        ),
      ),
    );
  }

  Future<void> _submitOpeningStock() async {
    final sessionId = _sessionId;
    final session = _session;
    final allItemsSaved =
        _items.isNotEmpty && _items.every((item) => item.saved);
    if (sessionId == null ||
        sessionId.isEmpty ||
        session == null ||
        !allItemsSaved ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await StockSessionService.submitOpeningStock(sessionId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      _showError(error, fallback: 'Unable to submit opening stock.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

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
      _showError(error, fallback: 'Unable to save opening quantity.');
    }
  }

  void _showError(
    Object error, {
    String fallback = 'Unable to load opening stock.',
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_readErrorMessage(error, fallback: fallback)),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
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
          const SizedBox(width: 48),
        ],
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

class _CountItemCard extends StatelessWidget {
  final _CountItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSave;

  const _CountItemCard({
    Key? key,
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSave,
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
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Opening qty',
            style: TextStyle(
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

class _CountBottomBar extends StatelessWidget {
  final int savedCount;
  final int itemCount;
  final bool isSubmitting;
  final Future<void> Function() onPrimaryPressed;

  const _CountBottomBar({
    Key? key,
    required this.savedCount,
    required this.itemCount,
    required this.isSubmitting,
    required this.onPrimaryPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allItemsSaved = itemCount > 0 && savedCount == itemCount;
    final canSubmit = allItemsSaved && !isSubmitting;

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
                      TextSpan(text: ' of $itemCount saved'),
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
                      allItemsSaved ? Icons.check_circle : Icons.error_outline,
                      color: allItemsSaved
                          ? AppColors.success
                          : AppColors.mutedText,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSubmitting
                          ? 'Submitting'
                          : allItemsSaved
                              ? 'Ready to submit'
                              : 'Save all items',
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
                onPressed: canSubmit ? onPrimaryPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD0D7E2),
                  disabledForegroundColor: AppColors.mutedText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSubmitting) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      isSubmitting ? 'Submitting opening' : 'Submit opening',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

  _CountItem({
    required this.lineId,
    required this.name,
    required this.sku,
    required this.quantity,
    this.saved = false,
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
    );
  }
}
