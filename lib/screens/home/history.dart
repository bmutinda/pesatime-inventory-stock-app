part of 'index.dart';

class _HistoryTab extends StatelessWidget {
  final List<StockSession> history;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  const _HistoryTab({
    Key? key,
    required this.history,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.appBlue,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        children: [
          const Text(
            'Stock session history',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track submitted and completed counts.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const _SessionsLoadingState()
          else if (errorMessage != null)
            _SessionsErrorState(message: errorMessage!, onRetry: onRetry)
          else if (history.isEmpty)
            const _HistoryEmptyState()
          else ...[
            for (final item in history) ...[
              _HistoryCard(item: item),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.history, color: AppColors.mutedText),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No stock session history yet.',
              style: TextStyle(
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

class _HistoryCard extends StatelessWidget {
  final StockSession item;

  const _HistoryCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool rejected = item.status.toLowerCase() == 'rejected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DEE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
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
                      item.title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _IconText(
                        icon: Icons.location_on_outlined, text: item.store),
                    const SizedBox(height: 6),
                    _IconText(
                      icon: rejected ? Icons.cancel : Icons.access_time,
                      text: item.dateText,
                    ),
                  ],
                ),
              ),
              _StatusPill(text: item.status, color: item.statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniChip(
                icon: Icons.inventory_2_outlined,
                text: '${item.totalItems} items',
              ),
              const SizedBox(width: 10),
              _MiniChip(
                icon: item.totalVariance == 0
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                text: '${item.totalVariance} variances',
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/history-detail',
                    arguments: item,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        rejected ? const Color(0xFFE11D48) : AppColors.appBlue,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: rejected
                          ? const Color(0xFFE11D48)
                          : AppColors.appBlue,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
