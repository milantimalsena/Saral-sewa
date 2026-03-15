import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String title;
  final String titleNp;
  final IconData icon;
  final String description;
  final List<String> steps;
  final List<String> requiredDocuments;
  final String officeNotice;
  final bool hasOnlineForm;
  final List<FormFieldDef>? formFields;
  final String? externalUrl;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.titleNp,
    required this.icon,
    required this.description,
    required this.steps,
    required this.requiredDocuments,
    required this.officeNotice,
    this.hasOnlineForm = false,
    this.formFields,
    this.externalUrl,
  });
}

class FormFieldDef {
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool isRequired;

  const FormFieldDef({
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.isRequired = true,
  });
}

/// All Nepal government services offered in the app.
class ServiceData {
  static const List<ServiceModel> allServices = [
    ServiceModel(
      id: 'passport',
      title: 'Passport',
      titleNp: 'राहदानी',
      icon: Icons.flight,
      description:
          'A Nepali passport (MRP) is issued by the Department of Passports, '
          'Ministry of Foreign Affairs. It is required for international travel.',
      steps: [
        'Fill the online application at nepalpassport.gov.np.',
        'Pay the passport fee online or at a bank.',
        'Collect required documents.',
        'Visit the Department of Passports or District Administration Office.',
        'Submit documents and application receipt.',
        'Provide biometric data and photo.',
        'Collect passport on the scheduled date.',
      ],
      requiredDocuments: [
        'Citizenship certificate (original and copy)',
        'Online application receipt',
        'Payment receipt (NPR 5,000 for normal / NPR 10,000 for express)',
        'Passport-size photos (recent)',
        'Old passport (if renewal)',
      ],
      officeNotice:
          'Visit the Department of Passports (Tripureshwor, Kathmandu) or your '
          'District Administration Office. Appointment date is shown on your '
          'online application receipt.',
      hasOnlineForm: true,
      externalUrl: 'https://emrtds.nepalpassport.gov.np/',
    ),
    ServiceModel(
      id: 'national_id',
      title: 'National ID',
      titleNp: 'राष्ट्रिय परिचयपत्र',
      icon: Icons.person,
      description:
          'The National Identity Card (NID) is a biometric identity document '
          'issued by the Government of Nepal. It serves as a universal identity '
          'proof and is linked to your citizenship record.',
      steps: [
        'Collect required documents.',
        'Fill the online application form.',
        'Visit the National ID enrollment center.',
        'Submit documents for verification.',
        'Provide biometric data (fingerprints, iris scan, photo).',
        'Receive enrollment receipt.',
        'Collect National ID card when ready.',
      ],
      requiredDocuments: [
        'Citizenship certificate (original and copy)',
        'Passport-size photos (2 copies)',
        'Birth certificate',
        'Proof of permanent address',
      ],
      officeNotice:
          'After submitting the online form, please visit the nearest National '
          'ID enrollment center for biometric verification and photo capture. '
          'Check enrollment center locations at nid.gov.np.',
      hasOnlineForm: true,
      externalUrl: 'https://citizenportal.donidcr.gov.np/en',
      formFields: [
        FormFieldDef(label: 'Full Name', hint: 'Enter your full name'),
        FormFieldDef(
          label: 'Date of Birth',
          hint: 'YYYY-MM-DD',
          keyboardType: TextInputType.datetime,
        ),
        FormFieldDef(
          label: 'Permanent Address',
          hint: 'District, Municipality, Ward',
        ),
        FormFieldDef(label: 'Gender', hint: 'Male / Female / Other'),
        FormFieldDef(
          label: 'Citizenship Number',
          hint: 'Enter citizenship number',
        ),
        FormFieldDef(
          label: 'Phone Number',
          hint: 'Enter 10-digit phone number',
          keyboardType: TextInputType.phone,
        ),
      ],
    ),
    ServiceModel(
      id: 'driving_license',
      title: 'Driving License',
      titleNp: 'सवारी चालक अनुमतिपत्र',
      icon: Icons.directions_car,
      description:
          'A driving license is issued by the Department of Transport Management '
          '(DoTM). It is mandatory for operating motor vehicles in Nepal.',
      steps: [
        'Fill the online application at dotm.gov.np.',
        'Pay the application fee.',
        'Visit the nearest Transport Management Office.',
        'Pass the written examination.',
        'Pass the trial (practical) examination.',
        'Provide biometric data and photo.',
        'Collect smart driving license card.',
      ],
      requiredDocuments: [
        'Citizenship certificate (original and copy)',
        'Medical fitness certificate from recognized hospital',
        'Online application receipt',
        'Payment receipt',
        'Passport-size photos (2 copies)',
        'Blood group report',
      ],
      officeNotice:
          'Visit the Department of Transport Management (DoTM) office nearest to '
          'you. Written exam and trial dates will be assigned after application '
          'submission. Check your exam date at dotm.gov.np.',
      hasOnlineForm: true,
      externalUrl: 'https://applydlnew.dotm.gov.np/',
      formFields: [
        FormFieldDef(label: 'Full Name', hint: 'As on citizenship certificate'),
        FormFieldDef(
          label: 'Date of Birth',
          hint: 'YYYY-MM-DD',
          keyboardType: TextInputType.datetime,
        ),
        FormFieldDef(
          label: 'Permanent Address',
          hint: 'District, Municipality, Ward',
        ),
        FormFieldDef(
          label: 'Citizenship Number',
          hint: 'Enter citizenship number',
        ),
        FormFieldDef(label: 'Blood Group', hint: 'A+ / B+ / O+ / AB+ etc.'),
        FormFieldDef(
          label: 'Phone Number',
          hint: 'Enter 10-digit phone number',
          keyboardType: TextInputType.phone,
        ),
      ],
    ),
    ServiceModel(
      id: 'citizenship',
      title: 'Citizenship',
      titleNp: 'नागरिकता',
      icon: Icons.badge,
      description:
          'Citizenship certificate is an official identity document issued by the '
          'District Administration Office (DAO) of Nepal. It is required for all '
          'government services, banking, property ownership, and more.',
      steps: [
        'Collect required documents.',
        'Fill the application form (available at DAO or ward office).',
        'Get a recommendation letter from your ward office.',
        'Visit the District Administration Office (DAO).',
        'Submit documents and application form.',
        'Take photo and biometric verification.',
        'Receive citizenship certificate.',
      ],
      requiredDocuments: [
        'Birth certificate',
        'Parent citizenship copy (both father and mother)',
        'Ward recommendation letter',
        'Passport-size photos (2 copies)',
        'School leaving certificate or equivalent',
        'Marriage certificate (for married women applying via husband)',
      ],
      officeNotice:
          'Please visit the District Administration Office (DAO) of your '
          'permanent district with all original documents. Office hours: '
          'Sunday–Friday, 10:00 AM – 5:00 PM (winter) / 10:00 AM – 4:00 PM (summer).',
    ),
    ServiceModel(
      id: 'birth_registration',
      title: 'Birth Registration',
      titleNp: 'जन्म दर्ता',
      icon: Icons.child_friendly,
      description:
          'Birth registration is a legal record of a child\'s birth maintained '
          'by the local government (ward office). It must be done within 35 days '
          'of birth as per Nepal law.',
      steps: [
        'Collect required documents.',
        'Visit the ward office of the birth place.',
        'Fill the birth registration form.',
        'Submit documents along with the form.',
        'Receive birth registration certificate.',
      ],
      requiredDocuments: [
        'Hospital birth record / delivery certificate',
        'Parent citizenship copies (father and mother)',
        'Parent marriage certificate',
        'Passport-size photo of the child (if above 1 year)',
      ],
      officeNotice:
          'Visit the ward office where the child was born. Birth registration '
          'is free within 35 days. A late fee applies after 35 days.',
    ),
    ServiceModel(
      id: 'marriage_registration',
      title: 'Marriage Registration',
      titleNp: 'विवाह दर्ता',
      icon: Icons.favorite,
      description:
          'Marriage registration is the legal documentation of marriage done at '
          'the local ward office. It is essential for legal recognition of the '
          'marriage and for updating citizenship records.',
      steps: [
        'Both spouses collect required documents.',
        'Visit the ward office together.',
        'Fill the marriage registration form.',
        'Submit documents and form.',
        'Two witnesses must be present with their citizenship copies.',
        'Receive marriage registration certificate.',
      ],
      requiredDocuments: [
        'Citizenship certificates of both spouses (original and copy)',
        'Passport-size photos of both spouses (2 each)',
        'Citizenship copies of two witnesses',
        'Consent letter from parents (if below 20 years)',
        'Divorce certificate (if previously married)',
      ],
      officeNotice:
          'Both spouses must be present at the ward office along with two '
          'witnesses. Office hours: Sunday–Friday, 10:00 AM – 3:00 PM.',
    ),
    ServiceModel(
      id: 'pan_card',
      title: 'PAN Card',
      titleNp: 'पान कार्ड',
      icon: Icons.credit_card,
      description:
          'Permanent Account Number (PAN) is issued by the Inland Revenue '
          'Department (IRD) for taxation purposes. It is required for opening '
          'bank accounts, property transactions, and business registration.',
      steps: [
        'Fill the online PAN application at ird.gov.np.',
        'Print the application acknowledgment.',
        'Collect required documents.',
        'Visit the nearest Inland Revenue Office.',
        'Submit documents and application.',
        'Receive PAN certificate.',
      ],
      requiredDocuments: [
        'Citizenship certificate (original and copy)',
        'Passport-size photos (2 copies)',
        'Proof of address',
        'Online application acknowledgment printout',
      ],
      officeNotice:
          'Visit the nearest Inland Revenue Office with original documents. '
          'PAN registration is free. Apply online at ird.gov.np first.',
      hasOnlineForm: true,
      formFields: [
        FormFieldDef(label: 'Full Name', hint: 'As on citizenship certificate'),
        FormFieldDef(
          label: 'Date of Birth',
          hint: 'YYYY-MM-DD',
          keyboardType: TextInputType.datetime,
        ),
        FormFieldDef(
          label: 'Permanent Address',
          hint: 'District, Municipality, Ward',
        ),
        FormFieldDef(
          label: 'Citizenship Number',
          hint: 'Enter citizenship number',
        ),
        FormFieldDef(
          label: 'Phone Number',
          hint: 'Enter 10-digit phone number',
          keyboardType: TextInputType.phone,
        ),
        FormFieldDef(
          label: 'Email',
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    ),
    ServiceModel(
      id: 'voter_id',
      title: 'Voter ID',
      titleNp: 'मतदाता परिचयपत्र',
      icon: Icons.how_to_vote,
      description:
          'Voter ID card is issued by the Election Commission of Nepal. It is '
          'required to cast votes in local, provincial, and federal elections.',
      steps: [
        'Check if voter registration is open (usually before elections).',
        'Visit the nearest voter registration center.',
        'Fill the voter registration form.',
        'Submit required documents.',
        'Provide photo and biometric data.',
        'Receive voter ID card.',
      ],
      requiredDocuments: [
        'Citizenship certificate (original and copy)',
        'Passport-size photos (2 copies)',
        'Proof of current residence',
      ],
      officeNotice:
          'Voter registration is conducted by the Election Commission during '
          'designated periods. Visit election.gov.np or your local election '
          'office for current registration schedule.',
    ),
    ServiceModel(
      id: 'police_clearance',
      title: 'Police Clearance',
      titleNp: 'प्रहरी क्लियरेन्स',
      icon: Icons.local_police,
      description:
          'Police Clearance Certificate (PCC) is an official document issued '
          'by Nepal Police verifying that the applicant has no criminal record.',
      steps: [
        'Collect required documents.',
        'Visit the nearest Police Station.',
        'Fill the PCC application form.',
        'Submit documents and pay fee.',
        'Police verification process.',
        'Collect PCC certificate.',
      ],
      requiredDocuments: [
        'Citizenship certificate (original and copy)',
        'Passport-size photos (2 copies)',
        'Old passport (if available)',
        'Purpose letter (for visa/travel)',
      ],
      officeNotice:
          'Apply at your nearest police station. Processing time may vary. '
          'For urgent cases, apply at Metropolitan Police Office.',
      externalUrl: 'https://nepalpolice.gov.np',
    ),
    ServiceModel(
      id: 'immigration',
      title: 'Immigration / Visa',
      titleNp: 'इमिग्रेशन / भिसा',
      icon: Icons.security,
      description:
          'Department of Immigration handles visa services, work permits, '
          'and travel documents for foreign nationals in Nepal.',
      steps: [
        'Check visa requirements.',
        'Collect required documents.',
        'Submit application online or at Immigration Office.',
        'Pay visa fee.',
        'Attend interview if required.',
        'Collect visa/stay permit.',
      ],
      requiredDocuments: [
        'Valid passport',
        ' passport-size photos',
        'Proof of financial means',
        'Travel itinerary',
        'Visa fee payment receipt',
      ],
      officeNotice:
          'Visit the Department of Immigration at Maitighar, Kathmandu. '
          'Office hours: Sunday–Friday, 10:00 AM – 5:00 PM.',
      externalUrl: 'https://nepaliport.immigration.gov.np',
    ),
    ServiceModel(
      id: 'passport_status',
      title: 'Passport Status',
      titleNp: 'राहदानी स्थिति',
      icon: Icons.search,
      description:
          'Check the status of your passport application online through the '
          'Department of Passport website.',
      steps: [
        'Visit the passport status check portal.',
        'Enter your application/reference number.',
        'View current status of your passport.',
      ],
      requiredDocuments: [
        'Application/Reference Number',
      ],
      officeNotice:
          'Check status online at nepalpassport.gov.np using your '
          'application reference number.',
      externalUrl: 'https://nepalpassport.gov.np',
    ),
  ];
}
