import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/screens/login/widgets.dart';
import 'package:inventory_app/services/auth/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _deviceCodeController = TextEditingController();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _openPinForConfiguredDevice();
  }

  Future<void> _openPinForConfiguredDevice() async {
    final code = await AuthUtils.getValidatedDeviceCode();
    if (code.isEmpty || !mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/staff-pin',
      arguments: {'deviceCode': code},
    );
  }

  @override
  void dispose() {
    _deviceCodeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final deviceCode = _deviceCodeController.text.trim();
    if (deviceCode.isEmpty || _isValidating) {
      if (!_isValidating) {
        LoginScaffold.showError(context, 'Enter the device code to continue.');
      }
      return;
    }

    setState(() => _isValidating = true);
    try {
      final validatedCode = await AuthUtils.validateDeviceCode(deviceCode);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/staff-pin',
        arguments: {'deviceCode': validatedCode},
      );
    } on AuthException catch (error) {
      if (mounted) LoginScaffold.showError(context, error.message);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginScaffold(
      title: 'Set up this device',
      subtitle:
          'Generate this code from Inventory Module \nStock App → Devices',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginTextField(
            controller: _deviceCodeController,
            label: 'Device code',
            hintText: 'Enter device code',
            prefixIcon: Icons.tablet_mac_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            enabled: !_isValidating,
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: 28),
          LoginButton(
            label: _isValidating ? 'Validating...' : 'Continue',
            loading: _isValidating,
            onPressed: _isValidating ? null : _continue,
          ),
        ],
      ),
    );
  }
}
