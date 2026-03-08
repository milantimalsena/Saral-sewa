import 'package:flutter/material.dart';

enum DocumentType {
  citizenship,
  nationalId,
  drivingLicense,
  passport,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.citizenship:
        return 'Citizenship';
      case DocumentType.nationalId:
        return 'National ID';
      case DocumentType.drivingLicense:
        return 'Driving License';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get displayNameNp {
    switch (this) {
      case DocumentType.citizenship:
        return 'नागरिकता';
      case DocumentType.nationalId:
        return 'राष्ट्रिय परिचयपत्र';
      case DocumentType.drivingLicense:
        return 'सवारी चालक अनुमतिपत्र';
      case DocumentType.passport:
        return 'राहदानी';
      case DocumentType.other:
        return 'अन्य';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.citizenship:
        return Icons.badge;
      case DocumentType.nationalId:
        return Icons.person;
      case DocumentType.drivingLicense:
        return Icons.directions_car;
      case DocumentType.passport:
        return Icons.flight;
      case DocumentType.other:
        return Icons.description;
    }
  }

  bool get requiresExpiryDate {
    return this == DocumentType.passport || this == DocumentType.drivingLicense;
  }
}

class DocumentModel {
  final String? id;
  final DocumentType type;
  final String documentNumber;
  final DateTime? expiryDate;
  final String? filePath;
  final String? fileName;
  final DateTime createdAt;

  DocumentModel({
    this.id,
    required this.type,
    required this.documentNumber,
    this.expiryDate,
    this.filePath,
    this.fileName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'documentNumber': documentNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'filePath': filePath,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String?,
      type: DocumentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DocumentType.other,
      ),
      documentNumber: json['documentNumber'] as String? ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  DocumentModel copyWith({
    String? id,
    DocumentType? type,
    String? documentNumber,
    DateTime? expiryDate,
    String? filePath,
    String? fileName,
    DateTime? createdAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      documentNumber: documentNumber ?? this.documentNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
}
