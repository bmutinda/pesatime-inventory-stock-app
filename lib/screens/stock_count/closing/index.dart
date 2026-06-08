import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/data/models/stock_session.dart';
import 'package:inventory_app/data/models/stock_session_item.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/stock_sessions/index.dart';

class ClosingStockScreen extends StatefulWidget {
  const ClosingStockScreen({Key? key}) : super(key: key);

  @override
  State<ClosingStockScreen> createState() => _ClosingStockScreenState();
}

class _ClosingStockScreenState extends State<ClosingStockScreen> {
  String? _sessionId;
  StockSession? _session;
  List<_CountItem> _items = const [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionId != null) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _sessionId = arguments['sessionId'] as String?;
    }

    _loadClosingStock();
  }

  Future<void> _loadClosingStock() async {
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
    return message.isEmpty ? 'Unable to load closing stock.' : message;
  }

  @override
  Widget build(BuildContext context) {
    final savedCount = _items.where((item) => item.saved).length;
    final missingReasons = _items
        .where((item) => item.variance != 0 && item.reason == null)
        .length;
    final filteredIndexes = _filteredItemIndexes;

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
              const _StockCountHeader(title: 'Closing Stock'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  children: [
                    if (_isLoading)
                      const _LoadingState()
                    else if (_errorMessage != null)
                      _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadClosingStock,
                      )
                    else if (_session == null)
                      const _EmptyState(message: 'Stock session not found.')
                    else ...[
                      _SessionSummaryCard(
                        session: _session!,
                        savedCount: savedCount,
                        itemCount: _items.length,
                      ),
                      const SizedBox(height: 16),
                      _ItemSearchField(
                        controller: _searchController,
                        onChanged: _updateSearchQuery,
                        onClear: _clearSearch,
                      ),
                      const SizedBox(height: 14),
                      if (_items.isEmpty)
                        const _EmptyState(
                          message: 'No items found for this stock session.',
                        )
                      else if (filteredIndexes.isEmpty)
                        const _EmptyState(
                          message: 'No items match your search.',
                        )
                      else
                        for (final index in filteredIndexes) ...[
                          _CountItemCard(
                            item: _items[index],
                            onDecrease: () => _changeQuantity(index, -1),
                            onIncrease: () => _changeQuantity(index, 1),
                            onSave: () => _saveItem(index),
                            onReasonSelected: (reason) =>
                                _selectReason(index, reason),
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
          savedCount: savedCount,
          itemCount: _items.length,
          missingReasons: missingReasons,
          onPrimaryPressed: _openClosingReview,
        ),
      ),
    );
  }

  void _openClosingReview() {
    if (_session == null) return;

    Navigator.of(context).pushNamed(
      '/closing-review',
      arguments: {
        'session': _session,
        'items': _items.map((item) => item.copy()).toList(),
      },
    );
  }

  void _changeQuantity(int index, int change) {
    setState(() {
      final int nextValue = _items[index].quantity + change;
      _items[index].quantity = nextValue < 0 ? 0 : nextValue;
      _items[index].saved = false;
      _items[index].variance = _items[index].quantity - _items[index].expected;
      if (_items[index].variance == 0) {
        _items[index].reason = null;
      }
    });
  }

  List<int> get _filteredItemIndexes {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return List<int>.generate(_items.length, (index) => index);
    }

    final indexes = <int>[];
    for (int index = 0; index < _items.length; index++) {
      final item = _items[index];
      final name = item.name.toLowerCase();
      final sku = item.sku.toLowerCase();
      if (name.contains(query) || sku.contains(query)) {
        indexes.add(index);
      }
    }

    return indexes;
  }

  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _updateSearchQuery('');
  }

  Future<void> _saveItem(int index) async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    try {
      await StockSessionService.submitClosingQty(
        sessionId: sessionId,
        lineId: _items[index].lineId,
        closingQty: _items[index].quantity.toDouble(),
        varianceReason: _items[index].reason,
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

  void _selectReason(int index, String reason) {
    setState(() {
      _items[index].reason = reason;
    });
  }
}

class ClosingReviewScreen extends StatefulWidget {
  const ClosingReviewScreen({Key? key}) : super(key: key);

  @override
  State<ClosingReviewScreen> createState() => _ClosingReviewScreenState();
}

class _ClosingReviewScreenState extends State<ClosingReviewScreen> {
  StockSession? _session;
  List<_CountItem> _items = const [];
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session != null || _items.isNotEmpty) return;

    final Object? args = ModalRoute.of(context)?.settings.arguments;
    _session =
        args is Map<String, dynamic> ? args['session'] as StockSession? : null;
    final Object? itemArgs =
        args is Map<String, dynamic> ? args['items'] : null;
    _items = itemArgs is List<_CountItem> ? itemArgs : const [];
  }

  Future<void> _submitClosingStock() async {
    final session = _session;
    final missingReasons = _missingReasons;
    if (session == null ||
        session.id.isEmpty ||
        missingReasons > 0 ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await StockSessionService.submitClosingStock(session.id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      _showError(error);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pushNamed(
      '/submission-success',
      arguments: {
        'countType': 'Closing stock',
        'title': 'Closing stock submitted',
        'store': session.store,
        'items': _items.length,
        'variances': _varianceCount,
      },
    );
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Unable to submit closing stock.' : message,
          ),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
  }

  int get _varianceCount => _items.where((item) => item.variance != 0).length;

  int get _missingReasons =>
      _items.where((item) => item.variance != 0 && item.reason == null).length;

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final items = _items;
    final varianceCount = _varianceCount;
    final missingReasons = _missingReasons;

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
              const _StockCountHeader(title: 'Review Closing'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  children: [
                    _ReviewSummaryCard(
                      session: session,
                      itemCount: items.length,
                      varianceCount: varianceCount,
                      missingReasons: missingReasons,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Items',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final item in items) ...[
                      _ReviewItemCard(item: item),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _ReviewBottomBar(
          session: session,
          disabled: missingReasons > 0,
          isSubmitting: _isSubmitting,
          onSubmit: _submitClosingStock,
        ),
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
                    const _MetaLine(
                      icon: Icons.lock_outline,
                      text: 'Opening locked',
                      color: Color(0xFF079455),
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
                    TextSpan(text: ' of $totalItems saved'),
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

class _ItemSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ItemSearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.isNotEmpty;

        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search items',
            hintStyle: const TextStyle(
              color: AppColors.inputIcon,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.mutedText,
              size: 24,
            ),
            suffixIcon: hasText
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.mutedText,
                      size: 22,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.appBlue,
                width: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountItemCard extends StatelessWidget {
  final _CountItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSave;
  final ValueChanged<String> onReasonSelected;

  const _CountItemCard({
    Key? key,
    required this.item,
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
              _VarianceBadge(variance: item.variance),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Expected  ${item.expected}    |    Opening  ${item.opening}',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Closing qty',
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
          if (item.variance != 0) ...[
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
  final int savedCount;
  final int itemCount;
  final int missingReasons;
  final VoidCallback onPrimaryPressed;

  const _CountBottomBar({
    Key? key,
    required this.savedCount,
    required this.itemCount,
    required this.missingReasons,
    required this.onPrimaryPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasMissingReasons = missingReasons > 0;

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
                      hasMissingReasons
                          ? Icons.error_outline
                          : Icons.check_circle,
                      color: hasMissingReasons
                          ? AppColors.mutedText
                          : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasMissingReasons
                          ? 'Reasons required'
                          : 'Ready to review',
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Review closing',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward, size: 20),
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

class _ReviewSummaryCard extends StatelessWidget {
  final StockSession? session;
  final int itemCount;
  final int varianceCount;
  final int missingReasons;

  const _ReviewSummaryCard({
    Key? key,
    required this.session,
    required this.itemCount,
    required this.varianceCount,
    required this.missingReasons,
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
          const Text(
            'Closing review',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (session != null) ...[
            const SizedBox(height: 8),
            Text(
              session!.title,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _MetaLine(
            icon: Icons.location_on_outlined,
            text: session?.store ?? 'Location',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ReviewStat(value: '$itemCount', label: 'Items'),
              const _ReviewDivider(),
              _ReviewStat(value: '$varianceCount', label: 'Variances'),
              const _ReviewDivider(),
              _ReviewStat(value: '$missingReasons', label: 'Missing reasons'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  final String value;
  final String label;

  const _ReviewStat({Key? key, required this.value, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDivider extends StatelessWidget {
  const _ReviewDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFD8DEE8),
    );
  }
}

class _ReviewItemCard extends StatelessWidget {
  final _CountItem item;

  const _ReviewItemCard({Key? key, required this.item}) : super(key: key);

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
                  item.name,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _VarianceBadge(variance: item.variance),
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
              _ReviewQuantity(label: 'Expected', value: item.expected),
              _ReviewQuantity(label: 'Opening', value: item.opening),
              _ReviewQuantity(label: 'Closing', value: item.quantity),
            ],
          ),
          if (item.variance != 0) ...[
            const SizedBox(height: 12),
            Text(
              item.reason == null
                  ? 'Reason required before submitting'
                  : 'Reason: ${item.reason}',
              style: TextStyle(
                color: item.reason == null
                    ? const Color(0xFFE11D48)
                    : AppColors.mutedText,
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

class _ReviewQuantity extends StatelessWidget {
  final String label;
  final int value;

  const _ReviewQuantity({Key? key, required this.label, required this.value})
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

class _ReviewBottomBar extends StatelessWidget {
  final StockSession? session;
  final bool disabled;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  const _ReviewBottomBar({
    Key? key,
    required this.session,
    required this.disabled,
    required this.isSubmitting,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canSubmit = !disabled && !isSubmitting && session != null;

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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canSubmit ? onSubmit : null,
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
                  isSubmitting
                      ? 'Submitting closing'
                      : disabled
                          ? 'Add variance reasons'
                          : 'Submit closing',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaLine({
    Key? key,
    required this.icon,
    required this.text,
    this.color = AppColors.mutedText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
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
    final int closingQty = item.closingQty.round();
    final int openingQty = item.openingQty.round();
    final int variance = item.varianceQty.round();

    return _CountItem(
      lineId: item.id,
      name: item.name,
      sku: item.sku,
      quantity: closingQty,
      expected: openingQty,
      opening: openingQty,
      variance: variance,
      reason: item.varianceReason.isEmpty ? null : item.varianceReason,
      saved: item.closingQty > 0,
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
