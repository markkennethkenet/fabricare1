import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppData.instance, AuthService.instance]),
      builder: (context, _) {
        final authUser = AuthService.instance.currentUser;
        if (authUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = AppData.instance.profileFor(authUser);
        final history = AppData.instance.history;
        final totalScans = history.length;
        final assessed = history.where((r) => r.hasHealthAssessment).toList();
        final avgHealth = assessed.isEmpty
            ? 0
            : (assessed.map((r) => r.healthScore!).reduce((a, b) => a + b) / assessed.length).round();
        final goodCount = assessed.where((r) => r.healthScore! >= 70).length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Header banner ───────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner background
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2B2119), Color(0xFF4A2E1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.coral.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: 60,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.mustard.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Back to top safe area padding
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            const Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: 'Fabri',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Care',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.coral),
                                ),
                              ]),
                            ),
                            const Spacer(),
                            // Edit button top-right
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Avatar + name positioned to overlap banner and body
                  Positioned(
                    bottom: -52,
                    left: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Initials avatar
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.coral,
                            border: Border.all(color: AppColors.background, width: 4),
                          ),
                          child: Center(
                            child: Text(
                              profile.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                profile.email,
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 68), // space for overlapping avatar

              // ── Stats row ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _StatCell(label: 'Total Scans', value: '$totalScans'),
                      _divider(),
                      _StatCell(label: 'Avg Health', value: totalScans == 0 ? '—' : '$avgHealth'),
                      _divider(),
                      _StatCell(label: 'Good+', value: '$goodCount'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings groups ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsGroup(
                      title: 'Account',
                      tiles: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          subtitle: 'Name, email, location',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Change Password',
                          subtitle: 'Update your password',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsGroup(
                      title: 'Data',
                      tiles: [
                        _SettingsTile(
                          icon: Icons.history_rounded,
                          label: 'Scan History',
                          subtitle: '$totalScans garments saved',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.delete_outline_rounded,
                          label: 'Clear Scan History',
                          subtitle: 'Remove all saved scans',
                          destructive: true,
                          onTap: () => _confirmClear(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsGroup(
                      title: 'About',
                      tiles: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About FabriCare',
                          subtitle: 'Version 1.0.0',
                          onTap: () => _showAbout(context),
                        ),
                        _SettingsTile(
                          icon: Icons.description_outlined,
                          label: 'Terms & Privacy Policy',
                          subtitle: 'How we use your data',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsGroup(
                      tiles: [
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          subtitle: 'Sign out of your account',
                          destructive: true,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        'FabriCare v1.0.0 · UI Prototype',
                        style: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.6), fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear scan history?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will remove all saved scans from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              AppData.instance.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Fabri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            TextSpan(text: 'Care', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.coral)),
          ]),
        ),
        content: const Text(
          'FabriCare helps you identify fabric types, assess garment condition, and get smart care recommendations to make your clothes last longer.\n\nVersion 1.0.0 · UI Prototype',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String? title;
  final List<_SettingsTile> tiles;
  const _SettingsGroup({this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(tiles.length * 2 - 1, (i) {
              if (i.isOdd) return Divider(height: 1, indent: 52, color: AppColors.border.withValues(alpha: 0.7));
              return tiles[i ~/ 2];
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    final bgColor = destructive ? AppColors.danger.withValues(alpha: 0.1) : AppColors.surfaceMuted;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13.5)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft, size: 20),
      onTap: onTap,
    );
  }
}
