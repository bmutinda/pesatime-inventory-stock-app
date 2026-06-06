import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/auth/index.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_StockSession> _sessions = const [
    _StockSession(
      title: 'Morning Count',
      store: 'Main Store',
      type: 'Opening stock',
      status: 'In progress',
      action: 'Continue',
      routeName: '/opening-stock',
      itemsSaved: 12,
      totalItems: 30,
      progress: 0.4,
      statusColor: AppColors.appBlue,
    ),
    _StockSession(
      title: 'Evening Count',
      store: 'Bar Store',
      type: 'Closing stock',
      status: 'Ready',
      action: 'Start',
      routeName: '/closing-stock',
      itemsSaved: 0,
      totalItems: 30,
      progress: 0,
      statusColor: AppColors.success,
    ),
  ];

  final List<_HistorySession> _history = const [
    _HistorySession(
      title: 'Evening Count',
      store: 'Bar Store',
      status: 'SUBMITTED',
      timestamp: 'Submitted today, 8:14 PM',
      items: 30,
      variances: 4,
      action: 'View',
      statusColor: AppColors.appBlue,
    ),
    _HistorySession(
      title: 'Morning Count',
      store: 'Main Store',
      status: 'APPROVED',
      timestamp: 'Approved Jun 4, 10:02 AM',
      items: 30,
      variances: 0,
      action: 'View',
      statusColor: AppColors.success,
    ),
    _HistorySession(
      title: 'Weekend Count',
      store: 'Kitchen',
      status: 'REJECTED',
      timestamp: 'Rejected Jun 3, 3:47 PM',
      items: 30,
      variances: 2,
      action: 'Review',
      reason: 'Recount damaged items',
      statusColor: Color(0xFFE11D48),
    ),
  ];

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
              _HomeHeader(title: _currentTitle),
              Expanded(
                child: _buildSelectedTab(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNavBar(
          selectedIndex: _selectedIndex,
          onChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  String get _currentTitle {
    if (_selectedIndex == 1) {
      return 'History';
    }
    if (_selectedIndex == 2) {
      return 'Profile';
    }
    return 'Home';
  }

  Widget _buildSelectedTab() {
    if (_selectedIndex == 1) {
      return _HistoryTab(history: _history);
    }
    if (_selectedIndex == 2) {
      return const _ProfileTab();
    }
    return _HomeTab(sessions: _sessions);
  }
}

class _HomeHeader extends StatelessWidget {
  final String title;

  const _HomeHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF3FF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7DCFF)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.appBlue,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF9FC3FF)),
            ),
            child: const Text(
              'BM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final List<_StockSession> sessions;

  const _HomeTab({Key? key, required this.sessions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned sessions',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '2 active',
              style: TextStyle(
                color: AppColors.appBlue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final session in sessions) ...[
          _SessionCard(session: session),
          const SizedBox(height: 18),
        ],
        const _RecentActivityCard(),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _StockSession session;

  const _SessionCard({Key? key, required this.session}) : super(key: key);

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
                    const _IconText(
                      icon: Icons.calendar_today_outlined,
                      text: 'Today, Jun 4',
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
                  onPressed: () => Navigator.of(context).pushNamed(
                    session.routeName,
                  ),
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

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({Key? key}) : super(key: key);

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
          Icon(Icons.check_circle, color: AppColors.success, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last saved: Opening stock, 8:14 PM',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<_HistorySession> history;

  const _HistoryTab({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        const _SearchBox(hintText: 'Search history'),
        const SizedBox(height: 16),
        const _HistoryFilterRow(),
        const SizedBox(height: 16),
        const _MonthSelector(),
        const SizedBox(height: 16),
        for (final item in history) ...[
          _HistoryCard(item: item),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  final String hintText;

  const _SearchBox({Key? key, required this.hintText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.inputIcon,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.mutedText),
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

class _HistoryFilterRow extends StatelessWidget {
  const _HistoryFilterRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _FilterChip(label: 'All', selected: true),
        SizedBox(width: 10),
        _FilterChip(label: 'Submitted'),
        SizedBox(width: 10),
        _FilterChip(label: 'Approved'),
        SizedBox(width: 10),
        _FilterChip(label: 'Rejected'),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({Key? key, required this.label, this.selected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.appBlue : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.appBlue : const Color(0xFFD0D7E2),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0D7E2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: AppColors.mutedText),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This month',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: AppColors.mutedText),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _HistorySession item;

  const _HistoryCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool rejected = item.status == 'REJECTED';

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
                      text: item.timestamp,
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
                text: '${item.items} items',
              ),
              const SizedBox(width: 10),
              _MiniChip(
                icon: item.variances == 0
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                text: '${item.variances} variances',
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/history-detail',
                    arguments: {
                      'title': item.title,
                      'store': item.store,
                      'status': item.status,
                      'timestamp': item.timestamp,
                      'items': item.items,
                      'variances': item.variances,
                      'reason': item.reason,
                      'statusColor': item.statusColor,
                    },
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
                  child: Text(
                    item.action,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (item.reason != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reason: ${item.reason}',
              style: const TextStyle(
                color: Color(0xFFE11D48),
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      children: const [
        _ProfileHeaderCard(),
        SizedBox(height: 14),
        _LogoutButton(),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0D7E2)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.appBlue,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'BM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boniface Mutinda',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
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

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({Key? key}) : super(key: key);

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    await AuthUtils.logout();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isSigningOut ? null : _signOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE11D48),
          side: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSigningOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE11D48),
                ),
              )
            : const Text(
                'Sign out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFD9E2F0)),
        ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
              _BottomNavItem(
                icon: Icons.history,
                selectedIcon: Icons.history,
                label: 'History',
                selected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
              _BottomNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                selected: selectedIndex == 2,
                onTap: () => onChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.appBlue : AppColors.mutedText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 86,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? AppColors.appBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Icon(selected ? selectedIcon : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockSession {
  final String title;
  final String store;
  final String type;
  final String status;
  final String action;
  final String routeName;
  final int itemsSaved;
  final int totalItems;
  final double progress;
  final Color statusColor;

  const _StockSession({
    required this.title,
    required this.store,
    required this.type,
    required this.status,
    required this.action,
    required this.routeName,
    required this.itemsSaved,
    required this.totalItems,
    required this.progress,
    required this.statusColor,
  });
}

class _HistorySession {
  final String title;
  final String store;
  final String status;
  final String timestamp;
  final int items;
  final int variances;
  final String action;
  final String? reason;
  final Color statusColor;

  const _HistorySession({
    required this.title,
    required this.store,
    required this.status,
    required this.timestamp,
    required this.items,
    required this.variances,
    required this.action,
    this.reason,
    required this.statusColor,
  });
}
