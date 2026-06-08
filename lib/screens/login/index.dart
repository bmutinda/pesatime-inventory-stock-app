import 'package:flutter/material.dart';
import 'package:inventory_app/helpers/colors.dart';
import 'package:inventory_app/services/auth/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _isPinHidden = true;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _staffCodeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final staffCode = _staffCodeController.text.trim();
    final pin = _pinController.text.trim();

    if (staffCode.isEmpty || pin.isEmpty) {
      _showError('Enter your staff code and PIN to continue.');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      await AuthUtils.login(
        staffCode: staffCode,
        pin: pin,
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to sign in. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: constraints.maxHeight < 720 ? 44 : 88,
                              ),
                              const _PesatimeBrand(),
                              const SizedBox(height: 24),
                              const _AppPurposeBadge(),
                              const SizedBox(height: 28),
                              const Text(
                                'Sign in to count stock',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Enter your staff code and PIN to\nview assigned sessions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 36),
                              _LoginTextField(
                                controller: _staffCodeController,
                                label: 'Staff Code',
                                hintText: 'Enter your staff code',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                enabled: !_isSigningIn,
                              ),
                              const SizedBox(height: 22),
                              _LoginTextField(
                                controller: _pinController,
                                label: 'PIN',
                                hintText: '••••',
                                prefixIcon: Icons.lock_outline,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                obscureText: _isPinHidden,
                                enabled: !_isSigningIn,
                                onSubmitted: (_) {
                                  if (!_isSigningIn) {
                                    _signIn();
                                  }
                                },
                                suffixIcon: IconButton(
                                  onPressed: _isSigningIn
                                      ? null
                                      : () {
                                          setState(() {
                                            _isPinHidden = !_isPinHidden;
                                          });
                                        },
                                  icon: Icon(
                                    _isPinHidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isSigningIn ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isSigningIn
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign in',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
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
                        ),
                      ),
                      const _LoginFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showManagerContact() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text(
            'Contact manager',
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Ask your manager to reset your stock taking PIN before signing in.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppColors.appBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PesatimeBrand extends StatelessWidget {
  const _PesatimeBrand({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 220,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AppPurposeBadge extends StatelessWidget {
  const _AppPurposeBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          color: AppColors.appBlue,
          size: 22,
        ),
        SizedBox(width: 8),
        Text(
          'Stock Taking App',
          style: TextStyle(
            color: AppColors.appBlue,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _LoginTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.textInputAction,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.inputIcon,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.inputIcon,
              size: 22,
            ),
            suffixIcon: suffixIcon,
            suffixIconColor: AppColors.inputIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.appBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                color: AppColors.success,
                size: 10,
              ),
              SizedBox(width: 8),
              Text(
                'Secure staff access',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
