import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'service_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _servicesFuture;
  late Future<List<dynamic>> _documentsFuture;
  late Future<List<dynamic>> _applicationsFuture;
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _apiService.fetchServices();
    _documentsFuture = _apiService.fetchDocuments();
    _applicationsFuture = _apiService.fetchApplications();
    _notificationsFuture = _apiService.fetchNotifications();
  }

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
                _buildPopularServices(context, _servicesFuture),
                const SizedBox(height: 28),

                // ── My Documents ──
                _buildSectionHeader(
                  'My Documents',
                  Icons.folder,
                  AppTheme.deepBlue,
                ),
                const SizedBox(height: 14),
                _buildMyDocuments(_documentsFuture),
                const SizedBox(height: 28),

                // ── Application Progress ──
                _buildSectionHeader(
                  'My Applications',
                  Icons.assignment,
                  AppTheme.crimsonRed,
                ),
                const SizedBox(height: 14),
                _buildApplicationProgress(_applicationsFuture),
                const SizedBox(height: 28),

                // ── Notifications ──
                _buildSectionHeader(
                  'Notifications',
                  Icons.notifications,
                  Colors.orange[700]!,
                ),
                const SizedBox(height: 14),
                _buildNotifications(_notificationsFuture),
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

  Widget _buildPopularServices(
    BuildContext context,
    Future<List<dynamic>> future,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = (snapshot.data ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(ServiceModel.fromApi)
            .take(6)
            .toList();

        if (services.isEmpty) {
          return const Text('No services available.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
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
      },
    );
  }

  // ─── My Documents ─────────────────────────────────────────────────────────

  Widget _buildMyDocuments(Future<List<dynamic>> future) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? <dynamic>[];
        if (items.isEmpty) {
          return const Text('No documents uploaded yet.');
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index] as Map<String, dynamic>;
              final status =
                  item['computed_status']?.toString() ??
                  item['status']?.toString() ??
                  'valid';
              final type =
                  item['document_type_display']?.toString() ??
                  item['document_type']?.toString() ??
                  'Document';
              final subtitle = status == 'expiring'
                  ? 'Expiring soon'
                  : status == 'expired'
                  ? 'Expired'
                  : 'Uploaded';

              return Column(
                children: [
                  _DocumentRow(
                    icon: status == 'expiring'
                        ? Icons.warning_amber_rounded
                        : status == 'expired'
                        ? Icons.error
                        : Icons.check_circle,
                    iconColor: status == 'expiring'
                        ? Colors.orange
                        : status == 'expired'
                        ? Colors.red
                        : Colors.green,
                    title: type,
                    subtitle: subtitle,
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // ─── Application Progress ─────────────────────────────────────────────────

  Widget _buildApplicationProgress(Future<List<dynamic>> future) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? <dynamic>[];
        if (items.isEmpty) {
          return const Text('No applications submitted yet.');
        }

        return Column(
          children: List.generate(items.length, (index) {
            final item = items[index] as Map<String, dynamic>;
            final service = item['service_name']?.toString() ?? 'Application';
            final status =
                item['status_display']?.toString() ??
                item['status']?.toString() ??
                'Pending';
            final statusRaw = item['status']?.toString() ?? 'pending';

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 12,
              ),
              child: _ApplicationCard(
                title: service,
                status: status,
                statusColor: _statusColor(statusRaw),
                icon: Icons.assignment,
                progress: _statusProgress(statusRaw),
              ),
            );
          }),
        );
      },
    );
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Widget _buildNotifications(Future<List<dynamic>> future) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? <dynamic>[];
        if (items.isEmpty) {
          return const Text('No notifications available.');
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index] as Map<String, dynamic>;
              final type = item['notification_type']?.toString() ?? 'info';
              return Column(
                children: [
                  _NotificationRow(
                    icon: _notificationIcon(type),
                    iconColor: _notificationColor(type),
                    text: item['message']?.toString() ?? '',
                    time: item['created_at']?.toString() ?? '',
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return AppTheme.deepBlue;
      default:
        return Colors.orange;
    }
  }

  double _statusProgress(String status) {
    switch (status) {
      case 'approved':
        return 1;
      case 'processing':
        return 0.6;
      case 'rejected':
        return 1;
      default:
        return 0.2;
    }
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'expiry_warning':
        return Icons.warning_amber_rounded;
      case 'application_update':
        return Icons.assignment_turned_in;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'expiry_warning':
        return Colors.orange;
      case 'application_update':
        return Colors.green;
      case 'system':
        return AppTheme.deepBlue;
      default:
        return AppTheme.deepBlue;
    }
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
