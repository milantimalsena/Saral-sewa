from django.core.management.base import BaseCommand
from core.models import Service


class Command(BaseCommand):
    help = 'Populate sample government services'

    def handle(self, *args, **options):
        services_data = [
            {
                'name': 'Citizenship Certificate',
                'name_nepali': 'नागरिकता प्रमाणपत्र',
                'description': 'Citizenship Certificate is a primary document that certifies Nepali citizenship. It is issued by District Administration Offices and is required for passport, national ID, and other official documents.',
                'department': 'District Administration Office',
                'steps': [
                    'Prepare required documents (birth certificate, parents\' citizenship, etc.)',
                    'Visit the District Administration Office (DAO)',
                    'Submit application form with documents',
                    'Pay applicable fee',
                    'Verify and collect documents during scheduled date',
                    'Receive citizenship certificate'
                ],
                'required_documents': [
                    'Birth certificate (original and copy)',
                    'Parents\' citizenship (original and copy)',
                    'Passport-size photos (2 copies)',
                    'Proof of permanent address',
                    'Identity proof of informant'
                ],
                'online_link': 'https://eservices.mha.gov.np/',
                'fee': 100,
                'processing_days': 7,
            },
            {
                'name': 'Passport',
                'name_nepali': 'राहदानी',
                'description': 'A Nepali passport is issued by the Department of Passports, Ministry of Foreign Affairs. It is required for international travel and is valid for 10 years for adults.',
                'department': 'Department of Passports',
                'steps': [
                    'Fill online application at nepalpassport.gov.np',
                    'Pay passport fee online (NPR 5,000 normal / NPR 10,000 express)',
                    'Collect required documents (citizenship, photos, etc.)',
                    'Visit Department of Passports or District Administration Office',
                    'Submit documents and receive appointment receipt',
                    'Provide biometric data (fingerprints, iris scan) and photo',
                    'Collect passport on scheduled date'
                ],
                'required_documents': [
                    'Citizenship certificate (original and copy)',
                    'Online application receipt',
                    'Payment receipt (NPR 5,000 or 10,000)',
                    'Passport-size photos (4 recent copies)',
                    'Old passport (if renewal)',
                    'Identity proof'
                ],
                'online_link': 'https://emrtds.nepalpassport.gov.np/',
                'fee': 5000,
                'processing_days': 10,
            },
            {
                'name': 'National ID',
                'name_nepali': 'राष्ट्रिय परिचयपत्र',
                'description': 'The National Identity Card (NID) is a biometric identity document issued by the Government of Nepal. It serves as a universal identity proof and is linked to citizenship records.',
                'department': 'Citizenship Registration Department',
                'steps': [
                    'Collect required documents (citizenship, photos, birth certificate)',
                    'Fill online application form',
                    'Visit nearest National ID enrollment center',
                    'Submit documents for verification',
                    'Provide biometric data (fingerprints, iris scan, photo)',
                    'Receive enrollment receipt',
                    'Collect National ID card when ready (usually 15-20 days)'
                ],
                'required_documents': [
                    'Citizenship certificate (original and copy)',
                    'Passport-size photos (2 copies)',
                    'Birth certificate (copy)',
                    'Proof of permanent address',
                    'Proof of temporary address (if different)'
                ],
                'online_link': 'https://citizenportal.donidcr.gov.np/en',
                'fee': 300,
                'processing_days': 15,
            },
            {
                'name': 'Driving License',
                'name_nepali': 'सवारी चालक अनुमतिपत्र',
                'description': 'A driving license issued by Department of Transport Management (DoTM). It is mandatory for operating motor vehicles in Nepal and is valid for 5 years.',
                'department': 'Department of Transport Management',
                'steps': [
                    'Fill online application at dotm.gov.np',
                    'Pass medical fitness test',
                    'Prepare required documents',
                    'Visit nearby DoTM office',
                    'Submit application with documents',
                    'Pass computer-based theory test',
                    'Pass practical driving test',
                    'Collect driving license'
                ],
                'required_documents': [
                    'Citizenship certificate (copy)',
                    'Medical fitness report (signed by authorized doctor)',
                    'Passport-size photos (3 copies)',
                    'Application form (filled and signed)',
                    'Vehicle registration (if applicable)',
                    'Proof of address'
                ],
                'online_link': 'https://dotm.gov.np/',
                'fee': 400,
                'processing_days': 7,
            },
            {
                'name': 'Birth Certificate',
                'name_nepali': 'जन्म प्रमाणपत्र',
                'description': 'Birth Certificate issued by local municipality/local body. It is an essential document for various government and private services.',
                'department': 'Local Municipality/Rural Municipality',
                'steps': [
                    'Collect required documents',
                    'Visit local municipality or rural municipality office',
                    'Submit birth registration form',
                    'Provide information of child and parents',
                    'Submit supporting documents',
                    'Pay registration fee',
                    'Receive birth certificate'
                ],
                'required_documents': [
                    'Hospital delivery report (if available)',
                    'Parent\'s citizenship certificate (copy)',
                    'Parent\'s marriage certificate (copy)',
                    'Passport-size photo of applicant'
                ],
                'online_link': 'https://eservices.mha.gov.np/',
                'fee': 50,
                'processing_days': 3,
            },
            {
                'name': 'Marriage Certificate',
                'name_nepali': 'विवाह प्रमाणपत्र',
                'description': 'Marriage Certificate issued by local municipality. Required for passport, visa, and other official purposes.',
                'department': 'Local Municipality/Rural Municipality',
                'steps': [
                    'Collect required documents from both parties',
                    'Visit local municipality office',
                    'Submit marriage registration form (signed by both parties)',
                    'Submit documents for verification',
                    'Pay registration fee',
                    'Receive marriage certificate'
                ],
                'required_documents': [
                    'Citizenship certificate of both parties (copy)',
                    'Passport-size photos (2 sets)',
                    'Two witness identity proofs (if married outside municipality)',
                    'Old marriage certificate (if re-registration)',
                    'Divorce certificate (if previously divorced)'
                ],
                'online_link': 'https://eservices.mha.gov.np/',
                'fee': 200,
                'processing_days': 3,
            },
        ]

        for service_data in services_data:
            service, created = Service.objects.update_or_create(
                name=service_data['name'],
                defaults=service_data
            )
            status = 'Created' if created else 'Updated'
            self.stdout.write(
                self.style.SUCCESS(f'{status} service: {service.name}')
            )

        self.stdout.write(
            self.style.SUCCESS('Successfully populated services')
        )
