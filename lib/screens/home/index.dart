import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/data/models/stock_session.dart';
import 'package:inventory_app/data/models/user.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/helpers/utils/date.dart';
import 'package:inventory_app/services/auth/index.dart';
import 'package:inventory_app/services/stock_sessions/index.dart';

part 'home.dart';
part 'history.dart';
part 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoadingSessions = true;
  String? _sessionsError;
  List<StockSession> _sessions = const [];
  bool _isLoadingHistory = true;
  String? _historyError;
  List<StockSession> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
    _loadHistorySessions();
  }

  Future<void> _loadActiveSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _sessionsError = null;
    });

    List<StockSession> sessions = const [];
    String? errorMessage;

    try {
      sessions = await StockSessionService.getActiveSessions();
    } catch (error) {
      errorMessage = _readErrorMessage(
        error,
        fallback: 'Unable to load active sessions.',
      );
    }

    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _sessionsError = errorMessage;
      _isLoadingSessions = false;
    });
  }

  String _readErrorMessage(
    Object error, {
    String fallback = 'Unable to load stock sessions.',
  }) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  Future<void> _loadHistorySessions() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    List<StockSession> history = const [];
    String? errorMessage;

    try {
      history = await StockSessionService.getHistorySessions();
    } catch (error) {
      errorMessage = _readErrorMessage(
        error,
        fallback: 'Unable to load stock session history.',
      );
    }

    if (!mounted) return;
    setState(() {
      _history = history;
      _historyError = errorMessage;
      _isLoadingHistory = false;
    });
  }

  Future<void> _refreshHomeData() async {
    await Future.wait([
      _loadActiveSessions(),
      _loadHistorySessions(),
    ]);
  }

  Future<void> _openSession(StockSession session) async {
    await Navigator.of(context).pushNamed(
      session.routeName,
      arguments: {
        'sessionId': session.id,
        'sessionName': session.title,
        'locationName': session.store,
      },
    );

    if (!mounted) return;
    await _refreshHomeData();
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
      return _HistoryTab(
        history: _history,
        isLoading: _isLoadingHistory,
        errorMessage: _historyError,
        onRetry: _loadHistorySessions,
        onRefresh: _loadHistorySessions,
      );
    }
    if (_selectedIndex == 2) {
      return const _ProfileTab();
    }
    return _HomeTab(
      sessions: _sessions,
      isLoading: _isLoadingSessions,
      errorMessage: _sessionsError,
      onRetry: _loadActiveSessions,
      onRefresh: _loadActiveSessions,
      onSessionSelected: _openSession,
    );
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
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
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
