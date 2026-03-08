import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/document_model.dart';
import '../theme.dart';
import '../services/api_service.dart';

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  DocumentType? _selectedDocumentType;
  final _documentNumberController = TextEditingController();
  DateTime? _expiryDate;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 20)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.crimsonRed,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _checkExpiryAndNotify(DocumentModel document) async {
    if (document.expiryDate == null) return;

    final daysUntilExpiry = document.daysUntilExpiry;
    if (daysUntilExpiry == null) return;

    if (daysUntilExpiry <= 30 && daysUntilExpiry >= 0) {
      await _showExpiryNotification(document, daysUntilExpiry);
      await _callExpiryNotificationAPI(document, daysUntilExpiry);
    }
  }

  Future<void> _showExpiryNotification(
    DocumentModel document,
    int daysLeft,
  ) async {
    final message =
        'Your ${document.type.displayName} will expire in $daysLeft days. Please renew it.';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.crimsonRed),
            const SizedBox(width: 8),
            const Text('Document Expiry Warning'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _callExpiryNotificationAPI(
    DocumentModel document,
    int daysLeft,
  ) async {
    // TODO: Replace with actual API call to backend notification service
    // Example API endpoint: POST /api/notifications/expiry
    // Body: {
    //   "documentType": document.type.name,
    //   "documentNumber": document.documentNumber,
    //   "expiryDate": document.expiryDate!.toIso8601String(),
    //   "daysUntilExpiry": daysLeft,
    //   "userId": "current_user_id"
    // }

    print('=== API CALL PLACEHOLDER ===');
    print('POST /api/notifications/expiry');
    print('Body: ${document.toJson()}');
    print('Days until expiry: $daysLeft');
    print('===========================');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDocumentType!.requiresExpiryDate && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date is required for this document type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final document = DocumentModel(
        type: _selectedDocumentType!,
        documentNumber: _documentNumberController.text.trim(),
        expiryDate: _expiryDate,
        filePath: _selectedFile!.path,
        fileName: _selectedFile!.name,
      );

      // TODO: Replace with actual API call
      // Example: await ApiService.uploadDocument(document);
      await _uploadDocumentAPI(document);

      // Check expiry and notify
      await _checkExpiryAndNotify(document);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _uploadDocumentAPI(DocumentModel document) async {
    final apiService = ApiService();
    await apiService.uploadDocument(
      documentType: document.type.name,
      documentNumber: document.documentNumber,
      expiryDate: document.expiryDate?.toIso8601String().split('T').first,
      filePath: document.filePath!,
      fileName: document.fileName!,
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedDocumentType = null;
      _documentNumberController.clear();
      _expiryDate = null;
      _selectedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Upload / दस्तावेज़ अपलोड'),
        backgroundColor: AppTheme.crimsonRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildDocumentTypeDropdown(),
                const SizedBox(height: 20),
                _buildDocumentNumberField(),
                const SizedBox(height: 20),
                _buildExpiryDatePicker(),
                const SizedBox(height: 20),
                _buildFileUploadSection(),
                const SizedBox(height: 32),
                _buildUploadButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.upload_file,
              color: AppTheme.deepBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Your Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepBlue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please fill in the details and upload your document',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Type / दस्तावेज़को प्रकार',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DocumentType>(
          initialValue: _selectedDocumentType,
          decoration: InputDecoration(
            hintText: 'Select document type',
            prefixIcon: Icon(
              _selectedDocumentType?.icon ?? Icons.description,
              color: AppTheme.crimsonRed,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.crimsonRed,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null) {
              return 'Please select a document type';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedDocumentType = value;
              if (!value!.requiresExpiryDate) {
                _expiryDate = null;
              }
            });
          },
          isExpanded: true,
          items: DocumentType.values.map((type) {
            return DropdownMenuItem<DocumentType>(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon, size: 20, color: AppTheme.deepBlue),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      '${type.displayName} (${type.displayNameNp})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Number / दस्तावेज़ नम्बर',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _documentNumberController,
          decoration: InputDecoration(
            hintText: 'Enter document number',
            prefixIcon: const Icon(Icons.numbers, color: AppTheme.crimsonRed),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.crimsonRed,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter document number';
            }
            if (value.trim().length < 4) {
              return 'Document number must be at least 4 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExpiryDatePicker() {
    final showExpiry = _selectedDocumentType?.requiresExpiryDate ?? false;

    if (!showExpiry) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expiry Date / म्याद समाप्त हुने मिति',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectExpiryDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.crimsonRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _expiryDate != null
                        ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                        : 'Select expiry date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _expiryDate != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Document File / फाइल अपलोड',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedFile != null
                  ? AppTheme.crimsonRed
                  : AppTheme.lightGrey,
              width: _selectedFile != null ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (_selectedFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.deepBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        color: AppTheme.deepBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.crimsonRed.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppTheme.crimsonRed,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tap to select file',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.crimsonRed,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG accepted',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.crimsonRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isUploading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload),
                SizedBox(width: 8),
                Text(
                  'Upload Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}

void checkAllDocumentExpiry(List<DocumentModel> documents) {
  for (final doc in documents) {
    if (doc.isExpiringSoon) {
      final days = doc.daysUntilExpiry;
      if (days != null) {
        print('NOTIFICATION: ${doc.type.displayName} expires in $days days');
      }
    }
  }
}
