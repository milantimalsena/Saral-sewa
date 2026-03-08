from django.db import models
import uuid


class ClerkUser(models.Model):
    """
    Local record for Clerk-authenticated users.
    Stores the Clerk user ID and cached profile data for local DB relations.
    Authentication is handled entirely by Clerk — this model is NOT a Django auth user.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    clerk_user_id = models.CharField(max_length=255, unique=True, db_index=True)
    email = models.EmailField(blank=True)
    full_name = models.CharField(max_length=255, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    image_url = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'clerk_users'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['clerk_user_id']),
            models.Index(fields=['email']),
        ]

    def __str__(self):
        return f"{self.email} ({self.clerk_user_id})"

    @property
    def is_authenticated(self):
        """Required by DRF so request.user.is_authenticated works."""
        return True


class Document(models.Model):
    DOCUMENT_TYPES = [
        ('citizenship', 'Citizenship'),
        ('national_id', 'National ID'),
        ('driving_license', 'Driving License'),
        ('passport', 'Passport'),
        ('other', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(ClerkUser, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=50, choices=DOCUMENT_TYPES)
    document_number = models.CharField(max_length=100)
    expiry_date = models.DateField(null=True, blank=True)
    file = models.FileField(upload_to='documents/', null=True, blank=True)
    file_name = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'documents'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.document_type} - {self.document_number}"
