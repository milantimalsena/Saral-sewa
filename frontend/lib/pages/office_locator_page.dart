import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// Model representing a government office location.
class GovernmentOffice {
  final String id;
  final String name;
  final String nameNp;
  final String type;
  final String address;
  final String contact;
  final double latitude;
  final double longitude;
  final IconData icon;

  const GovernmentOffice({
    required this.id,
    required this.name,
    required this.nameNp,
    required this.type,
    required this.address,
    required this.contact,
    required this.latitude,
    required this.longitude,
    required this.icon,
  });
}

/// Sample government offices in Kathmandu Valley.
const List<GovernmentOffice> _sampleOffices = [
  GovernmentOffice(
    id: 'dao_ktm',
    name: 'Kathmandu District Administration Office',
    nameNp: 'काठमाडौं जिल्ला प्रशासन कार्यालय',
    type: 'District Administration Office',
    address: 'Babar Mahal, Kathmandu',
    contact: '+977-1-4211215',
    latitude: 27.6933,
    longitude: 85.3211,
    icon: Icons.account_balance,
  ),
  GovernmentOffice(
    id: 'ward_lalitpur',
    name: 'Lalitpur Metropolitan City Ward Office No. 10',
    nameNp: 'ललितपुर महानगरपालिका वडा कार्यालय नं. १०',
    type: 'Ward Office',
    address: 'Kupondole, Lalitpur',
    contact: '+977-1-5521718',
    latitude: 27.6840,
    longitude: 85.3188,
    icon: Icons.location_city,
  ),
  GovernmentOffice(
    id: 'passport_ktm',
    name: 'Department of Passport',
    nameNp: 'राहदानी विभाग',
    type: 'Passport Office',
    address: 'Tripureshwor, Kathmandu',
    contact: '+977-1-4211220',
    latitude: 27.6958,
    longitude: 85.3115,
    icon: Icons.menu_book,
  ),
  GovernmentOffice(
    id: 'dotm_ktm',
    name: 'Department of Transport Management',
    nameNp: 'यातायात व्यवस्था विभाग',
    type: 'Transport Management Office',
    address: 'Ekantakuna, Lalitpur',
    contact: '+977-1-5529067',
    latitude: 27.6700,
    longitude: 85.3092,
    icon: Icons.directions_car,
  ),
  GovernmentOffice(
    id: 'nid_ktm',
    name: 'National ID Registration Center',
    nameNp: 'राष्ट्रिय परिचयपत्र दर्ता केन्द्र',
    type: 'National ID Center',
    address: 'Singha Durbar, Kathmandu',
    contact: '+977-1-4200100',
    latitude: 27.7020,
    longitude: 85.3206,
    icon: Icons.badge,
  ),
  GovernmentOffice(
    id: 'dao_bhaktapur',
    name: 'Bhaktapur District Administration Office',
    nameNp: 'भक्तपुर जिल्ला प्रशासन कार्यालय',
    type: 'District Administration Office',
    address: 'Durbarmarg, Bhaktapur',
    contact: '+977-1-6610108',
    latitude: 27.6712,
    longitude: 85.4298,
    icon: Icons.account_balance,
  ),
  GovernmentOffice(
    id: 'immigration_ktm',
    name: 'Department of Immigration',
    nameNp: 'अध्यागमन विभाग',
    type: 'Immigration Office',
    address: 'Kalikasthan, Kathmandu',
    contact: '+977-1-4429660',
    latitude: 27.7130,
    longitude: 85.3230,
    icon: Icons.flight,
  ),
  GovernmentOffice(
    id: 'land_revenue_ktm',
    name: 'Land Revenue Office, Kathmandu',
    nameNp: 'मालपोत कार्यालय, काठमाडौं',
    type: 'Land Revenue Office',
    address: 'Dilli Bazaar, Kathmandu',
    contact: '+977-1-4411503',
    latitude: 27.7050,
    longitude: 85.3260,
    icon: Icons.landscape,
  ),
];

/// Office Locator page – Google Maps with government office markers.
class OfficeLocatorPage extends StatefulWidget {
  const OfficeLocatorPage({super.key});

  @override
  State<OfficeLocatorPage> createState() => _OfficeLocatorPageState();
}

class _OfficeLocatorPageState extends State<OfficeLocatorPage> {
  final Completer<GoogleMapController> _mapController = Completer();

  // Default center: Kathmandu
  static const LatLng _defaultCenter = LatLng(27.7000, 85.3240);

  Position? _currentPosition;
  bool _loadingLocation = true;
  String? _locationError;
  String _selectedFilter = 'All';

  final Set<Marker> _markers = {};

  static const List<String> _officeTypes = [
    'All',
    'District Administration Office',
    'Ward Office',
    'Passport Office',
    'Transport Management Office',
    'National ID Center',
    'Immigration Office',
    'Land Revenue Office',
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _buildMarkers();
  }

  List<GovernmentOffice> get _filteredOffices {
    if (_selectedFilter == 'All') return _sampleOffices;
    return _sampleOffices.where((o) => o.type == _selectedFilter).toList();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingLocation = false;
          _locationError = 'Location services are disabled';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loadingLocation = false;
            _locationError = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _locationError = 'Location permission permanently denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });

      // Animate to user location
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _locationError = 'Could not get location';
      });
    }
  }

  void _buildMarkers() {
    _markers.clear();
    for (final office in _filteredOffices) {
      _markers.add(
        Marker(
          markerId: MarkerId(office.id),
          position: LatLng(office.latitude, office.longitude),
          infoWindow: InfoWindow(title: office.name, snippet: office.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _markerHueForType(office.type),
          ),
          onTap: () => _onMarkerTapped(office),
        ),
      );
    }
  }

  double _markerHueForType(String type) {
    switch (type) {
      case 'District Administration Office':
        return BitmapDescriptor.hueRed;
      case 'Ward Office':
        return BitmapDescriptor.hueBlue;
      case 'Passport Office':
        return BitmapDescriptor.hueGreen;
      case 'Transport Management Office':
        return BitmapDescriptor.hueOrange;
      case 'National ID Center':
        return BitmapDescriptor.hueViolet;
      case 'Immigration Office':
        return BitmapDescriptor.hueCyan;
      case 'Land Revenue Office':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueRose;
    }
  }

  void _onMarkerTapped(GovernmentOffice office) {
    _showOfficeBottomSheet(office);
  }

  Future<void> _openDirections(GovernmentOffice office) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${office.latitude},${office.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _showOfficeBottomSheet(GovernmentOffice office) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OfficeDetailSheet(
        office: office,
        onDirections: () {
          Navigator.pop(context);
          _openDirections(office);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _animateToOffice(GovernmentOffice office) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(office.latitude, office.longitude),
        16.0,
      ),
    );
    _onMarkerTapped(office);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Locator / कार्यालय खोज'),
        backgroundColor: AppTheme.crimsonRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Office List',
            onPressed: _showOfficeListSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterBar(),
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : _defaultCenter,
                    zoom: 13.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: _currentPosition != null,
                  myLocationButtonEnabled: _currentPosition != null,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                ),
                // Loading overlay
                if (_loadingLocation)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.crimsonRed,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Getting your location...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Location error banner
                if (_locationError != null && !_loadingLocation)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _locationError = null);
                              },
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // FAB to recenter on user location
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton.small(
              backgroundColor: AppTheme.crimsonRed,
              foregroundColor: Colors.white,
              onPressed: () async {
                final controller = await _mapController.future;
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    14.0,
                  ),
                );
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _officeTypes.map((type) {
            final isSelected = _selectedFilter == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  type == 'All' ? 'All Offices' : type,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selectedColor: AppTheme.crimsonRed,
                backgroundColor: AppTheme.offWhite,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppTheme.crimsonRed : AppTheme.lightGrey,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = type;
                    _buildMarkers();
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOfficeListSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: AppTheme.crimsonRed),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Government Offices / सरकारी कार्यालय',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredOffices.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final office = _filteredOffices[index];
                  return _OfficeListTile(
                    office: office,
                    onTap: () {
                      Navigator.pop(context);
                      _animateToOffice(office);
                    },
                    onDirections: () {
                      Navigator.pop(context);
                      _openDirections(office);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet showing office details when a marker is tapped
// ---------------------------------------------------------------------------
class _OfficeDetailSheet extends StatelessWidget {
  final GovernmentOffice office;
  final VoidCallback onDirections;
  final VoidCallback onClose;

  const _OfficeDetailSheet({
    required this.office,
    required this.onDirections,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.crimsonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(office.icon, color: AppTheme.crimsonRed, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      office.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      office.nameNp,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Info rows
          _InfoRow(
            icon: Icons.category,
            label: 'Office Type',
            value: office.type,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.location_on,
            label: 'Address',
            value: office.address,
          ),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.phone, label: 'Contact', value: office.contact),
          const SizedBox(height: 20),
          // Directions button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions / दिशा निर्देश'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Call button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse('tel:${office.contact}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.call),
              label: const Text('Call Office / कार्यालयमा फोन'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.crimsonRed,
                side: const BorderSide(color: AppTheme.crimsonRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable info row widget
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.deepBlue),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// List tile for the office list bottom sheet
// ---------------------------------------------------------------------------
class _OfficeListTile extends StatelessWidget {
  final GovernmentOffice office;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _OfficeListTile({
    required this.office,
    required this.onTap,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.crimsonRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(office.icon, color: AppTheme.crimsonRed, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    office.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    office.type,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          office.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.directions, color: AppTheme.deepBlue),
              tooltip: 'Directions',
              onPressed: onDirections,
            ),
          ],
        ),
      ),
    );
  }
}
