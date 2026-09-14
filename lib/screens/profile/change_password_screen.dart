import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  // Password strength
  int get _strength {
    final p = _newPass.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(p)) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.mustard;
      case 3:
        return AppColors.sage;
      case 4:
        return const Color(0xFF3A9B5C);
      default:
        return AppColors.border;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _current.text,
        newPassword: _newPass.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: AppColors.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mustard.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.mustard.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.mustard),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use at least 8 characters with uppercase, numbers, and symbols for a strong password.',
                          style: TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _fieldLabel('Current Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _current,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: _eyeButton(_obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 20),

                _fieldLabel('New Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newPass,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                    suffixIcon: _eyeButton(_obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'At least 8 characters required';
                    if (v == _current.text) return 'New password must differ from current';
                    return null;
                  },
                ),
                // Strength indicator
                if (_newPass.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _strength / 4,
                            minHeight: 5,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(_strengthColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _strengthLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _strengthColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _PasswordHints(password: _newPass.text),
                ],
                const SizedBox(height: 20),

                _fieldLabel('Confirm New Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: _eyeButton(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  ),
                  validator: (v) => v != _newPass.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));

  Widget _eyeButton(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
      onPressed: onTap,
    );
  }
}

class _PasswordHints extends StatelessWidget {
  final String password;
  const _PasswordHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = [
      (label: 'At least 8 characters', met: password.length >= 8),
      (label: 'Uppercase letter (A-Z)', met: RegExp(r'[A-Z]').hasMatch(password)),
      (label: 'Number (0-9)', met: RegExp(r'[0-9]').hasMatch(password)),
      (label: 'Symbol (!@#\$...)', met: RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(password)),
    ];
    return Column(
      children: checks
          .map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      c.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: c.met ? AppColors.sage : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      c.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.met ? AppColors.sage : AppColors.inkSoft,
                        fontWeight: c.met ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
