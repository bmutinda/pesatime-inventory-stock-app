import 'package:flutter/material.dart';
import 'package:inventory_app/helpers/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPinHidden = true;

  void _signIn() {
    Navigator.of(context).pushReplacementNamed('/home');
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
                              const SizedBox(height: 30),
                              const _AppPurposeBadge(),
                              const SizedBox(height: 34),
                              const Text(
                                'Sign in to count stock',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Enter your staff code and PIN to\nview assigned sessions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 48),
                              const _LoginTextField(
                                label: 'Staff Code',
                                hintText: 'Enter your staff code',
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 28),
                              _LoginTextField(
                                label: 'PIN',
                                hintText: '••••',
                                prefixIcon: Icons.lock_outline,
                                keyboardType: TextInputType.number,
                                obscureText: _isPinHidden,
                                suffixIcon: IconButton(
                                  onPressed: () {
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
                              const SizedBox(height: 42),
                              SizedBox(
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              TextButton(
                                onPressed: _showManagerContact,
                                child: const Text(
                                  'Forgot PIN? Contact manager',
                                  style: TextStyle(
                                    color: AppColors.appBlue,
                                    fontSize: 18,
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
        width: 260,
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
          size: 30,
        ),
        SizedBox(width: 12),
        Text(
          'Stock Taking App',
          style: TextStyle(
            color: AppColors.appBlue,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _LoginTextField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.textInputAction,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
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
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.inputIcon,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.inputIcon,
              size: 28,
            ),
            suffixIcon: suffixIcon,
            suffixIconColor: AppColors.inputIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 22,
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
                size: 14,
              ),
              SizedBox(width: 12),
              Text(
                'Secure staff access',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
