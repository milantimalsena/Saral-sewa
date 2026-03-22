"""
Management command to seed the database with sample data.
Usage: python manage.py seed_data
"""
import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from core.models import User, Service, Document, Application, Notification


class Command(BaseCommand):
    help = 'Seed database with sample data for Saral Sewa'

    def handle(self, *args, **options):
        self.stdout.write('🌱 Seeding database...')

        # Create admin user
        admin, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@saralsewa.gov.np',
                'first_name': 'Admin',
                'last_name': 'Saral Sewa',
                'is_staff': True,
                'is_superuser': True,
                'phone': '+977-9801000000',
            }
        )
        if created:
            admin.set_password('admin123')
            admin.save()
            self.stdout.write(self.style.SUCCESS('  ✅ Admin user created (admin / admin123)'))

        # Create services
        services_data = [
            ('Citizenship Certificate', 'नागरिकता प्रमाण पत्र', 'District Administration Office', 500),
            ('Passport', 'राहदानी', 'Department of Passports', 5000),
            ('Driving License', 'सवारी चालक अनुमतिपत्र', 'Department of Transport', 3000),
            ('Birth Certificate', 'जन्मदर्ता प्रमाणपत्र', 'Local Government Office', 100),
            ('Land Registration', 'जग्गा दर्ता', 'Land Revenue Office', 10000),
            ('Business Registration', 'व्यापार दर्ता', 'Office of Company Registrar', 7000),
            ('Marriage Certificate', 'विवाह दर्ता', 'Local Government Office', 200),
            ('PAN Registration', 'स्थायी लेखा नम्बर', 'Inland Revenue Department', 0),
        ]
        services = []
        for name, name_np, dept, fee in services_data:
            svc, _ = Service.objects.get_or_create(
                name=name,
                defaults={
                    'name_nepali': name_np,
                    'department': dept,
                    'fee': fee,
                    'processing_days': random.randint(3, 30),
                }
            )
            services.append(svc)
        self.stdout.write(self.style.SUCCESS(f'  ✅ {len(services)} services created'))

        # Create sample users with more realistic data
        nepali_names = [
            ('Ram', 'Sharma', 'Kathmandu Metropolitan-10, Baneshwor'), 
            ('Sita', 'Adhikari', 'Pokhara Metropolitan-8, Srijanachowk'), 
            ('Hari', 'Poudel', 'Lalitpur Metropolitan-3, Jhamsikhel'),
            ('Gita', 'Shrestha', 'Bhaktapur Municipality-5, Taumadhi'), 
            ('Krishna', 'Thapa', 'Biratnagar Metropolitan-2, Tinpania'), 
            ('Sarita', 'Gurung', 'Dharan Sub-Metropolitan-15, Pindeshor'),
            ('Bikash', 'Maharjan', 'Kirtipur Municipality-2, Devdhoka'), 
            ('Anita', 'Rai', 'Ilam Municipality-7, Tundikhel'), 
            ('Prakash', 'Tamang', 'Hetauda Sub-Metropolitan-4, Karra'),
            ('Sunita', 'Lama', 'Banepa Municipality-8, Naya Basti'), 
            ('Roshan', 'Karki', 'Bharatpur Metropolitan-10, Hakimchowk'), 
            ('Maya', 'Bhandari', 'Butwal Sub-Metropolitan-9, Milan Chowk'),
            ('Dipak', 'Khadka', 'Nepalgunj Sub-Metropolitan-12, Dhamboji'), 
            ('Kamala', 'Basnet', 'Dhangadhi Sub-Metropolitan-5, Hasanpur'), 
            ('Santosh', 'Ghimire', 'Birendranagar Municipality-6, Mangalgadhi'),
            ('Puja', 'Pokhrel', 'Tansen Municipality-4, Taksar'), 
            ('Anil', 'Pandey', 'Baglung Municipality-2, Srinagar'), 
            ('Nirmala', 'Subedi', 'Ghorahi Sub-Metropolitan-15, Ratanpur'),
            ('Suresh', 'Koirala', 'Damak Municipality-5, Beldangi'), 
            ('Bindu', 'Chand', 'Mahendranagar Municipality-18, Bhimdattanagar'),
        ]
        users = []
        for i, (first, last, address) in enumerate(nepali_names):
            username = f'{first.lower()}.{last.lower()}{random.randint(1,99)}'
            
            # Generate realistic Nepali phone numbers that start with 984, 985, 986, 980, 981
            prefix = random.choice(['984', '985', '986', '980', '981', '982'])
            phone_num = f'+977-{prefix}{random.randint(1000000, 9999999)}'
            
            # Generate realistic citizenship numbers like 27-01-79-12345
            cit_num = f'{random.randint(10, 77)}-{random.randint(1, 10):02d}-{random.randint(60, 80)}-{random.randint(10000, 99999)}'

            user, created = User.objects.get_or_create(
                username=username,
                defaults={
                    'email': f'{username}@example.com.np',
                    'first_name': first,
                    'last_name': last,
                    'phone': phone_num,
                    'address': address,
                    'citizenship_number': cit_num,
                    'is_verified': random.choice([True, True, True, False]), # 75% verified
                }
            )
            if created:
                user.set_password('password123')
                # Spread out join dates over last 6 months
                days_ago = random.randint(0, 180)
                user.date_joined = timezone.now() - timedelta(days=days_ago)
                user.save()
            users.append(user)
        self.stdout.write(self.style.SUCCESS(f'  ✅ {len(users)} users created'))

        # Create documents with realistic numbering schemes
        doc_types = ['citizenship', 'passport', 'driving_license', 'voter_id', 'pan_card']
        docs_created = 0
        for user in users:
            for _ in range(random.randint(1, 4)):
                doc_type = random.choice(doc_types)
                days_offset = random.randint(-60, 1000)
                expiry = timezone.now().date() + timedelta(days=days_offset)
                if days_offset < 0:
                    doc_status = 'expired'
                elif days_offset <= 30:
                    doc_status = 'expiring'
                else:
                    doc_status = 'valid'

                # Format document numbers realistically based on type
                if doc_type == 'citizenship':
                    doc_num = user.citizenship_number
                elif doc_type == 'passport':
                    doc_num = f'PA{random.randint(1000000, 9999999)}'
                elif doc_type == 'driving_license':
                    doc_num = f'01-{random.randint(10, 20)}-{random.randint(1000000, 9999999)}'
                elif doc_type == 'voter_id':
                    doc_num = f'{random.randint(10000000, 99999999)}'
                else: # pan_card
                    doc_num = f'{random.randint(100000000, 999999999)}'

                Document.objects.get_or_create(
                    user=user,
                    document_type=doc_type,
                    defaults={
                        'document_number': doc_num,
                        'issue_date': timezone.now().date() - timedelta(days=random.randint(365, 3650)),
                        'expiry_date': expiry,
                        'status': doc_status,
                    }
                )
                docs_created += 1
        self.stdout.write(self.style.SUCCESS(f'  ✅ {docs_created} documents created'))

        # Create realistic applications
        statuses = ['pending', 'processing', 'approved', 'rejected']
        # Weight statuses so approved is most common
        status_weights = ['pending', 'pending', 'processing', 'approved', 'approved', 'approved', 'rejected']
        
        remarks_list = [
            'All required documents attached and verified by ward office.',
            'Urgent request for foreign travel. Please expedite if possible.',
            'First time applicant. Submitted original academic certificates.',
            'Renewal application. Previous document number attached.',
            'Pending verification of land tax receipt from local municipality.',
            'Minor applicant. Father\'s citizenship attached as witness.',
            'Migrated from another district. Migration certificate provided.',
            'Document damaged. Applying for a copy with police report.',
            'Applying for correction of name spelling as per academic records.',
            'Standard application submitted via Saral Sewa portal.'
        ]
        
        apps_created = 0
        for user in users:
            for _ in range(random.randint(0, 3)):
                Application.objects.create(
                    user=user,
                    service=random.choice(services),
                    status=random.choice(status_weights),
                    remarks=random.choice(remarks_list),
                )
                apps_created += 1
        self.stdout.write(self.style.SUCCESS(f'  ✅ {apps_created} applications created'))

        # Create notifications
        notif_count = 0
        for doc in Document.objects.filter(status='expiring'):
            days_left = (doc.expiry_date - timezone.now().date()).days
            if days_left > 0:
                Notification.objects.get_or_create(
                    user=doc.user,
                    notification_type='expiry_warning',
                    message=f'{doc.get_document_type_display()} ({doc.document_number}) '
                            f'will expire in {days_left} days.',
                    defaults={
                        'title': 'Document Expiring Soon',
                        'is_admin': True,
                    }
                )
                notif_count += 1

        # System notifications
        Notification.objects.get_or_create(
            title='System Maintenance',
            notification_type='system',
            defaults={
                'message': 'Scheduled maintenance on Saturday 10 PM - 2 AM NPT.',
                'is_admin': True,
            }
        )
        Notification.objects.get_or_create(
            title='New Service Available',
            notification_type='info',
            defaults={
                'message': 'Online Business Registration is now available through Saral Sewa.',
                'is_admin': True,
            }
        )
        notif_count += 2
        self.stdout.write(self.style.SUCCESS(f'  ✅ {notif_count} notifications created'))

        self.stdout.write(self.style.SUCCESS('\n🎉 Database seeded successfully!'))
        self.stdout.write(self.style.WARNING('   Admin login: admin / admin123'))
