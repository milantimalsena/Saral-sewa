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
