import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'saral_sewa.settings')
django.setup()

from authentication.models import CustomUser

# Check if admin already exists
if CustomUser.objects.filter(email='admin@saral-sewa.com').exists():
    print("Admin user already exists!")
else:
    # Create admin user
    admin = CustomUser.objects.create_superuser(
        email='admin@saral-sewa.com',
        full_name='Admin User',
        username='admin',
        password='AdminPass123'
    )
    print("✓ Admin account created successfully!")
    print(f"  Email: admin@saral-sewa.com")
    print(f"  Password: AdminPass123")
    print(f"  Username: admin")
    print(f"\n  Access admin panel at: http://127.0.0.1:8000/admin/")
