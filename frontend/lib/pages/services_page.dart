import 'package:flutter/material.dart';
import '../theme.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_Service> _allServices = [
    const _Service(
      icon: Icons.badge,
      title: 'Citizenship',
      titleNp: 'नागरिकता',
    ),
    const _Service(
      icon: Icons.flight,
      title: 'Passport',
      titleNp: 'राहदानी',
    ),
    const _Service(
      icon: Icons.directions_car,
      title: 'Driving License',
      titleNp: 'सवारी चालक अनुमतिपत्र',
    ),
    const _Service(
      icon: Icons.credit_card,
      title: 'PAN Card',
      titleNp: 'पान कार्ड',
    ),
    const _Service(
      icon: Icons.how_to_vote,
      title: 'Voter ID',
      titleNp: 'मतदाता परिचयपत्र',
    ),
    const _Service(
      icon: Icons.child_friendly,
      title: 'Birth Registration',
      titleNp: 'जन्म दर्ता',
    ),
    const _Service(
      icon: Icons.favorite,
      title: 'Marriage Registration',
      titleNp: 'विवाह दर्ता',
    ),
    const _Service(
      icon: Icons.person,
      title: 'National ID',
      titleNp: 'राष्ट्रिय परिचयपत्र',
    ),
  ];

  List<_Service> get _filteredServices {
    if (_searchQuery.isEmpty) {
      return _allServices;
    }
    return _allServices.where((service) {
      final query = _searchQuery.toLowerCase();
      return service.title.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services / सेवाहरू'),
        backgroundColor: AppTheme.crimsonRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildServicesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.crimsonRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search services / सेवा खोज्नुहोस्',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: AppTheme.crimsonRed),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = _filteredServices;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) => _ServiceCard(service: services[index]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _Service {
  final IconData icon;
  final String title;
  final String titleNp;

  const _Service({
    required this.icon,
    required this.title,
    required this.titleNp,
  });
}

class _ServiceCard extends StatelessWidget {
  final _Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${service.title} - Coming soon'),
              backgroundColor: AppTheme.deepBlue,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  service.icon,
                  color: AppTheme.deepBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                service.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                service.titleNp,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
