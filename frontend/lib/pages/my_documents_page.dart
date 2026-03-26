import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({super.key});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  // Document type colors
  static const Map<String, Color> documentTypeColors = {
    'citizenship': Color(0xFFE8F5E9),
    'nationalId': Color(0xFFE3F2FD),
    'drivingLicense': Color(0xFFFFF3E0),
    'passport': Color(0xFFF3E5F5),
    'other': Color(0xFFF5F5F5),
  };

  static const Map<String, IconData> documentTypeIcons = {
    'citizenship': Icons.badge,
    'nationalId': Icons.person,
    'drivingLicense': Icons.directions_car,
    'passport': Icons.flight,
    'other': Icons.description,
  };

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchDocuments();
      if (!mounted) return;

      setState(() {
        _documents = List<Map<String, dynamic>>.from(
          data.whereType<Map<String, dynamic>>(),
        );
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load documents: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDocuments {
    if (_selectedFilter == 'all') {
      return _documents;
    }
    return _documents
        .where((doc) => doc['document_type'] == _selectedFilter)
        .toList();
  }

  String _getDocumentTypeLabel(String type) {
    const typeLabels = {
      'citizenship': 'Citizenship',
      'nationalId': 'National ID',
      'drivingLicense': 'Driving License',
      'passport': 'Passport',
      'other': 'Other',
    };
    return typeLabels[type] ?? type;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'valid':
        return Colors.green;
      case 'expiring':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'valid':
        return 'Valid';
      case 'expiring':
        return 'Expiring Soon';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Future<void> _openDocument(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document file not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Document?'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Call delete endpoint when available
        // await _apiService.deleteDocument(docId);

        setState(() {
          _documents.removeWhere((doc) => doc['id'] == docId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents / मेरा दस्तावेज़'),
        backgroundColor: AppTheme.crimsonRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _documents.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  _buildFilterBar(),
                  Expanded(child: _buildDocumentList()),
                ],
              ),
      ),
      floatingActionButton: _documents.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/document-upload'),
              backgroundColor: AppTheme.crimsonRed,
              icon: const Icon(Icons.add),
              label: const Text('Upload New'),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.crimsonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.folder_open,
                size: 48,
                color: AppTheme.crimsonRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Documents Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your documents to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/document-upload'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.crimsonRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final documentTypes = [
      ('all', 'All'),
      ('citizenship', 'Citizenship'),
      ('nationalId', 'National ID'),
      ('drivingLicense', 'License'),
      ('passport', 'Passport'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: documentTypes.map((type) {
            final isSelected = _selectedFilter == type.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.$2),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = type.$1;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.crimsonRed.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? AppTheme.crimsonRed : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDocumentList() {
    final docs = _filteredDocuments;

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: docs.length,
        itemBuilder: (context, index) => _buildDocumentCard(docs[index]),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docType = doc['document_type'] ?? 'other';
    final docTypeLabel = _getDocumentTypeLabel(docType);
    final docNumber = doc['document_number'] ?? 'N/A';
    final expiryDate = doc['expiry_date'];
    final status = doc['computed_status'] ?? doc['status'] ?? 'valid';
    final fileUrl = doc['document_file_url'];
    final uploadedDate = doc['created_at'];
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header with type and status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    documentTypeColors[docType] ?? documentTypeColors['other'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      documentTypeIcons[docType] ?? Icons.description,
                      color: AppTheme.deepBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docTypeLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Number: $docNumber',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expiryDate != null) ...[
                    _buildDetailRow('Expiry Date', _formatDate(expiryDate)),
                    const SizedBox(height: 8),
                  ],
                  _buildDetailRow('Uploaded', _formatDate(uploadedDate)),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: fileUrl != null
                              ? () => _openDocument(fileUrl)
                              : null,
                          icon: const Icon(Icons.visibility),
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepBlue,
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: fileUrl != null
                            ? () => _downloadDocument(fileUrl, docNumber)
                            : null,
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.crimsonRed,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () => _deleteDocument(doc['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
