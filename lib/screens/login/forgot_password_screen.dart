import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/animated_error_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordResetEmail(email);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra email (cả thư rác) để đặt lại mật khẩu!')),
      );
      context.pop();
    } else if (auth.lastError.isNotEmpty && context.mounted) {
      AnimatedErrorDialog.show(
        context, 
        title: "Lỗi", 
        message: auth.lastError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.loginBackgroundGradientDark
              : AppColors.loginBackgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email của bạn',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.mail, size: 20),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Nhận Link đổi mật khẩu',
                      isLoading: auth.isLoading,
                      onPressed: _sendResetLink,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: Text(
                          'Quay lại',
                          style: TextStyle(color: AppColors.primaryGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
