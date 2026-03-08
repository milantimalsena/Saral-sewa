import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import 'service_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saral Sewa'),
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton(
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    child: const Text('Profile'),
                    onTap: () {
                      Navigator.of(context).pushNamed('/profile');
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Sign Out'),
                    onTap: () => _handleSignOut(context, authProvider),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.user!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Card ──
                _buildWelcomeCard(user),
                const SizedBox(height: 28),

                // ── Popular Services ──
                _buildSectionHeader(
                  'Popular Services',
                  Icons.star,
                  Colors.amber[700]!,
                ),
                const SizedBox(height: 14),
                _buildPopularServices(context),
                const SizedBox(height: 28),

                // ── My Documents ──
                _buildSectionHeader(
                  'My Documents',
                  Icons.folder,
                  AppTheme.deepBlue,
                ),
                const SizedBox(height: 14),
                _buildMyDocuments(),
                const SizedBox(height: 28),

                // ── Application Progress ──
                _buildSectionHeader(
                  'My Applications',
                  Icons.assignment,
                  AppTheme.crimsonRed,
                ),
                const SizedBox(height: 14),
                _buildApplicationProgress(),
                const SizedBox(height: 28),

                // ── Notifications ──
                _buildSectionHeader(
                  'Notifications',
                  Icons.notifications,
                  Colors.orange[700]!,
                ),
                const SizedBox(height: 14),
                _buildNotifications(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Welcome Card ─────────────────────────────────────────────────────────

  Widget _buildWelcomeCard(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.crimsonRed, AppTheme.deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crimsonRed.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Namaste, ${user.firstName} 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Welcome to Saral Sewa\nYour guide to Nepal Government Services',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ─── Popular Services Grid ────────────────────────────────────────────────

  Widget _buildPopularServices(BuildContext context) {
    final popular = ServiceData.allServices
        .where(
          (s) => [
            'citizenship',
            'national_id',
            'passport',
            'driving_license',
            'birth_registration',
            'pan_card',
          ].contains(s.id),
        )
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: popular.length,
      itemBuilder: (context, index) {
        final service = popular[index];
        return _ServiceTile(
          icon: service.icon,
          label: service.title,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailPage(service: service),
              ),
            );
          },
        );
      },
    );
  }

  // ─── My Documents ─────────────────────────────────────────────────────────

  Widget _buildMyDocuments() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        children: [
          _DocumentRow(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Citizenship',
            subtitle: 'Uploaded',
          ),
          const Divider(height: 1),
          _DocumentRow(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: 'Passport',
            subtitle: 'Expires in 3 months',
          ),
          const Divider(height: 1),
          _DocumentRow(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Driving License',
            subtitle: 'Uploaded',
          ),
          const Divider(height: 1),
          _DocumentRow(
            icon: Icons.upload_file,
            iconColor: Colors.grey,
            title: 'PAN Card',
            subtitle: 'Not uploaded yet',
          ),
        ],
      ),
    );
  }

  // ─── Application Progress ─────────────────────────────────────────────────

  Widget _buildApplicationProgress() {
    return Column(
      children: [
        _ApplicationCard(
          title: 'National ID Application',
          status: 'Pending biometric verification',
          statusColor: Colors.orange,
          icon: Icons.person,
          progress: 0.6,
        ),
        const SizedBox(height: 12),
        _ApplicationCard(
          title: 'Passport Renewal',
          status: 'Processing',
          statusColor: AppTheme.deepBlue,
          icon: Icons.flight,
          progress: 0.35,
        ),
      ],
    );
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Widget _buildNotifications() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        children: [
          _NotificationRow(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            text: 'Your passport expires in 30 days',
            time: '2 hours ago',
          ),
          const Divider(height: 1),
          _NotificationRow(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            text: 'National ID form submitted successfully',
            time: '1 day ago',
          ),
          const Divider(height: 1),
          _NotificationRow(
            icon: Icons.info,
            iconColor: AppTheme.deepBlue,
            text: 'New: Online PAN registration available',
            time: '3 days ago',
          ),
        ],
      ),
    );
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> _handleSignOut(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.deepBlue, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _DocumentRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final IconData icon;
  final double progress;

  const _ApplicationCard({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Status: $status',
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String time;

  const _NotificationRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 14, height: 1.3)),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
