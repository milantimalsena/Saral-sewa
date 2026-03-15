import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';
import '../theme.dart';

class ServiceDetailPage extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late List<bool> _checkedDocuments;
  final _formKey = GlobalKey<FormState>();
  late List<TextEditingController> _formControllers;
  bool _formSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkedDocuments = List.filled(
      widget.service.requiredDocuments.length,
      false,
    );
    _formControllers = List.generate(
      widget.service.formFields?.length ?? 0,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _formControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(
        title: Text(service.title),
        backgroundColor: AppTheme.crimsonRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(service),
            const SizedBox(height: 24),
            _buildDescription(service),
            const SizedBox(height: 24),
            _buildStepByStep(service),
            const SizedBox(height: 24),
            _buildDocumentChecklist(service),
            if (service.hasOnlineForm && service.formFields != null) ...[
              const SizedBox(height: 24),
              _buildOnlineForm(service),
            ],
            const SizedBox(height: 24),
            _buildOfficeNotice(service),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ServiceModel service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.crimsonRed, AppTheme.deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(service.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.titleNp,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.deepBlue, size: 22),
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

  Widget _buildDescription(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About this Service', Icons.info_outline),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Text(
            service.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepByStep(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Step-by-Step Process', Icons.format_list_numbered),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: List.generate(service.steps.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.crimsonRed,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          service.steps[index],
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentChecklist(ServiceModel service) {
    final checkedCount = _checkedDocuments.where((v) => v).length;
    final total = service.requiredDocuments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Required Documents', Icons.checklist),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: checkedCount == total
                    ? Colors.green.withValues(alpha: 0.15)
                    : AppTheme.crimsonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$checkedCount / $total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: checkedCount == total
                      ? Colors.green[700]
                      : AppTheme.crimsonRed,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: List.generate(service.requiredDocuments.length, (index) {
              return CheckboxListTile(
                title: Text(
                  service.requiredDocuments[index],
                  style: TextStyle(
                    fontSize: 14,
                    decoration: _checkedDocuments[index]
                        ? TextDecoration.lineThrough
                        : null,
                    color: _checkedDocuments[index]
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
                value: _checkedDocuments[index],
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() {
                    _checkedDocuments[index] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineForm(ServiceModel service) {
    if (_formSubmitted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Online Form', Icons.edit_document),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Form Submitted Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please visit the designated office for biometric verification '
                  'and document submission.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.green[700]),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _formSubmitted = false;
                      for (final c in _formControllers) {
                        c.clear();
                      }
                    });
                  },
                  child: const Text('Submit Another'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Online Form', Icons.edit_document),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ...List.generate(service.formFields!.length, (index) {
                  final field = service.formFields![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: _formControllers[index],
                      keyboardType: field.keyboardType,
                      decoration: InputDecoration(
                        labelText: field.label,
                        hintText: field.hint,
                      ),
                      validator: field.isRequired
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '${field.label} is required';
                              }
                              return null;
                            }
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                if (service.externalUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openExternalUrl(service.externalUrl!),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Official Website'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be redirected to the official government portal',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('OR', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Form'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _formSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Form submitted successfully. Please visit the office for verification.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOfficeNotice(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Office Visit Information', Icons.location_city),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.deepBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: AppTheme.deepBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.officeNotice,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
