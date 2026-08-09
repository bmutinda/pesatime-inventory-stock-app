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
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final filteredIndexes = _filteredItemIndexes;

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
                            onQuantityChanged: (value) =>
                                _updateQuantity(index, value),
                            onReasonChanged: (value) =>
                                _updateReason(index, value),
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
        'variances': _items.where((item) => item.hasVariance).length,
      },
    );
  }

  void _changeQuantity(int index, double change) {
    setState(() {
      final double nextValue = _items[index].quantity + change;
      _items[index].quantity = _roundQuantity(nextValue < 0 ? 0 : nextValue);
      if (!_items[index].hasVariance) {
        _items[index].reason = null;
      }
      _items[index].saved = false;
    });
  }

  void _updateQuantity(int index, double value) {
    setState(() {
      _items[index].quantity = _roundQuantity(value < 0 ? 0 : value);
      if (!_items[index].hasVariance) {
        _items[index].reason = null;
      }
      _items[index].saved = false;
    });
  }

  void _updateReason(int index, String value) {
    setState(() {
      _items[index].reason = value;
      _items[index].saved = false;
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

    final item = _items[index];
    final reason = item.reason?.trim();
    if (item.hasVariance && (reason == null || reason.isEmpty)) {
      _showError(
        Exception('Enter a reason for the opening stock variance.'),
        fallback: 'Enter a reason for the opening stock variance.',
      );
      return;
    }

    try {
      await StockSessionService.submitOpeningQty(
        sessionId: sessionId,
        lineId: item.lineId,
        openingQty: item.quantity,
        varianceReason: item.hasVariance ? reason : null,
      );

      if (!mounted) return;
      setState(() {
        _items[index].saved = true;
      });
      FocusManager.instance.primaryFocus?.unfocus();
      _showSavedToast('${item.name} saved');
    } catch (error) {
      if (!mounted) return;
      _showError(error, fallback: 'Unable to save opening quantity.');
    }
  }

  void _showSavedToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF079455),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFD5FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0055C8),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
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
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onReasonChanged;
  final VoidCallback onSave;

  const _CountItemCard({
    Key? key,
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onQuantityChanged,
    required this.onReasonChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.hasVariance
              ? const Color(0xFFF5C58B)
              : const Color(0xFFD8E0EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.appBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
              _ItemStatusPill(saved: item.saved),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE1E7EF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.balance_outlined,
                  color: AppColors.mutedText,
                  size: 20,
                ),
                const SizedBox(width: 9),
                const Text(
                  'Expected Balance',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatQuantity(item.openingBalance),
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (item.hasVariance) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE36C0A),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Variance ${_formatSignedQuantity(item.quantity - item.openingBalance)}',
                      style: const TextStyle(
                        color: Color(0xFFB54708),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Counted quantity',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Enter the physical quantity available',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuantityStepper(
                value: item.quantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
                onChanged: onQuantityChanged,
              ),
              const Spacer(),
              _SaveButton(onPressed: onSave),
            ],
          ),
          if (item.hasVariance) ...[
            const SizedBox(height: 14),
            TextFormField(
              key: ValueKey(item.lineId),
              initialValue: item.reason,
              onChanged: onReasonChanged,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Variance reason',
                hintText: 'Enter why the opening count differs',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: AppColors.appBlue,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatefulWidget {
  final double value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<double> onChanged;

  const _QuantityStepper({
    Key? key,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<_QuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatQuantity(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _formatQuantity(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _controller.text = _formatQuantity(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 204,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD0D7E2)),
      ),
      child: Row(
        children: [
          _StepperButton(icon: Icons.remove, onPressed: widget.onDecrease),
          Expanded(
            child: Center(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.onChanged(double.tryParse(value) ?? 0);
                },
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  _quantityInputFormatter,
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onPressed: widget.onIncrease),
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

class _ItemStatusPill extends StatelessWidget {
  final bool saved;

  const _ItemStatusPill({Key? key, required this.saved}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: saved ? const Color(0xFFEAF8F0) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: saved ? const Color(0xFFA6E0BC) : const Color(0xFFD5DCE6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            saved ? Icons.check_circle : Icons.edit_outlined,
            color: saved ? AppColors.success : AppColors.mutedText,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            saved ? 'Saved' : 'Not saved',
            style: TextStyle(
              color: saved ? const Color(0xFF079455) : AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
  final double openingBalance;
  double quantity;
  bool saved;
  String? reason;

  _CountItem({
    required this.lineId,
    required this.name,
    required this.sku,
    required this.openingBalance,
    required this.quantity,
    this.saved = false,
    this.reason,
  });

  bool get hasVariance =>
      _roundQuantity(quantity) != _roundQuantity(openingBalance);

  factory _CountItem.fromSessionItem(StockSessionItem item) {
    return _CountItem(
      lineId: item.id,
      name: item.name,
      sku: item.sku,
      openingBalance: _roundQuantity(item.openingBalance),
      quantity: _roundQuantity(item.openingQty),
      saved: item.openingCounted,
      reason: item.openingVarianceReason.isEmpty
          ? null
          : item.openingVarianceReason,
    );
  }

  _CountItem copy() {
    return _CountItem(
      lineId: lineId,
      name: name,
      sku: sku,
      openingBalance: openingBalance,
      quantity: quantity,
      saved: saved,
      reason: reason,
    );
  }
}

double _roundQuantity(double value) {
  return double.parse(value.toStringAsFixed(2));
}

String _formatQuantity(double value) {
  final text = _roundQuantity(value).toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatSignedQuantity(double value) {
  final formatted = _formatQuantity(value);
  return value > 0 ? '+$formatted' : formatted;
}

final TextInputFormatter _quantityInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
  return RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
      ? newValue
      : oldValue;
});
