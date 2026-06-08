part of 'index.dart';

class _HomeTab extends StatelessWidget {
  final List<StockSession> sessions;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final Future<void> Function(StockSession session) onSessionSelected;

  const _HomeTab({
    Key? key,
    required this.sessions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
    required this.onSessionSelected,
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
            'Stock taking',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View assigned counts and submit stock quantities.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 17,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned sessions',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${sessions.length} active',
                style: const TextStyle(
                  color: AppColors.appBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const _SessionsLoadingState()
          else if (errorMessage != null)
            _SessionsErrorState(message: errorMessage!, onRetry: onRetry)
          else if (sessions.isEmpty)
            const _SessionsEmptyState()
          else
            for (final session in sessions) ...[
              _SessionCard(
                session: session,
                onSelected: () => onSessionSelected(session),
              ),
              const SizedBox(height: 18),
            ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final StockSession session;
  final VoidCallback onSelected;

  const _SessionCard({
    Key? key,
    required this.session,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int percent = (session.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8DEE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _IconText(
                      icon: Icons.location_on_outlined,
                      text: session.store,
                    ),
                    const SizedBox(height: 6),
                    _IconText(
                      icon: Icons.calendar_today_outlined,
                      text: session.dateText,
                    ),
                  ],
                ),
              ),
              _StatusPill(
                text: session.status,
                color: session.statusColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${session.itemsSaved}',
                      style: const TextStyle(
                        color: AppColors.appBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: ' of ${session.totalItems} saved'),
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
                '$percent%',
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
              value: session.progress,
              minHeight: 8,
              color: AppColors.appBlue,
              backgroundColor: const Color(0xFFE4E8EF),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniChip(
                icon: Icons.category_outlined,
                text: session.type,
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: onSelected,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.appBlue,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(
                      color: AppColors.appBlue,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    session.action,
                    style: const TextStyle(
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

class _SessionsLoadingState extends StatelessWidget {
  const _SessionsLoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.appBlue,
        ),
      ),
    );
  }
}

class _SessionsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SessionsErrorState({
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
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE11D48),
            size: 28,
          ),
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

class _SessionsEmptyState extends StatelessWidget {
  const _SessionsEmptyState({Key? key}) : super(key: key);

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
          Icon(Icons.inventory_2_outlined, color: AppColors.mutedText),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No active stock sessions assigned.',
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

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconText({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mutedText, size: 19),
        const SizedBox(width: 7),
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

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniChip({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.mutedText, size: 20),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
