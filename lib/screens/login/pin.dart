import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/screens/login/widgets.dart';
import 'package:inventory_app/services/auth/index.dart';

class StaffPinScreen extends StatefulWidget {
  const StaffPinScreen({super.key});

  @override
  State<StaffPinScreen> createState() => _StaffPinScreenState();
}

class _StaffPinScreenState extends State<StaffPinScreen> {
  final _pinController = TextEditingController();
  bool _hidePin = true;
  bool _isSigningIn = false;
  bool _isResettingDevice = false;
  String _businessName = '';
  String _unitName = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceDetails();
  }

  Future<void> _loadDeviceDetails() async {
    final values = await Future.wait([
      AuthUtils.getBusinessName(),
      AuthUtils.getUnitName(),
    ]);
    if (!mounted) return;
    setState(() {
      _businessName = values[0];
      _unitName = values[1];
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<String> _readDeviceCode() async {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            const {};
    final routeCode = arguments['deviceCode'] as String? ?? '';
    return routeCode.isNotEmpty
        ? routeCode
        : AuthUtils.getValidatedDeviceCode();
  }

  Future<void> _signIn() async {
    final pin = _pinController.text.trim();
    if (_isSigningIn) return;
    if (pin.length < 4) {
      LoginScaffold.showError(context, 'Enter your 4-digit staff PIN.');
      return;
    }

    final code = await _readDeviceCode();
    if (code.isEmpty) {
      if (!mounted) return;
      LoginScaffold.showError(
        context,
        'Device code is missing. Validate the device again.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    setState(() => _isSigningIn = true);
    try {
      await AuthUtils.login(code: code, pin: pin);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on AuthException catch (error) {
      if (mounted) LoginScaffold.showError(context, error.message);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _resetDevice() async {
    if (_isSigningIn || _isResettingDevice) return;

    setState(() => _isResettingDevice = true);
    await AuthUtils.resetDeviceOnboarding();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final destination = [_businessName, _unitName]
        .where((value) => value.isNotEmpty)
        .join(' · ');

    return LoginScaffold(
      title: 'Welcome back',
      subtitle: destination.isEmpty
          ? 'Enter your staff PIN to continue.'
          : 'Enter your staff PIN to continue to $destination.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginTextField(
            controller: _pinController,
            label: 'Staff PIN',
            hintText: '••••',
            prefixIcon: Icons.lock_outline,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            obscureText: _hidePin,
            enabled: !_isSigningIn,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onSubmitted: (_) => _signIn(),
            suffixIcon: IconButton(
              onPressed: _isSigningIn
                  ? null
                  : () => setState(() => _hidePin = !_hidePin),
              icon: Icon(
                _hidePin
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 28),
          LoginButton(
            label: _isSigningIn ? 'Signing in...' : 'Sign in',
            loading: _isSigningIn,
            onPressed: _isSigningIn || _isResettingDevice ? null : _signIn,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSigningIn || _isResettingDevice ? null : _resetDevice,
            icon: _isResettingDevice
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restart_alt_rounded),
            label: Text(
              _isResettingDevice ? 'Resetting device...' : 'Reset Device',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.appBlue,
              side: const BorderSide(color: AppColors.appBlue),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: _showManagerContact,
            child: const Text(
              'Forgot PIN? Contact manager',
              style: TextStyle(
                color: AppColors.appBlue,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManagerContact() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact manager'),
        content: const Text(
          'Ask your manager to reset your stock taking PIN before signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
