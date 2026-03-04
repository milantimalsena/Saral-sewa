from rest_framework import serializers
from authentication.models import ClerkUser


class ClerkUserSerializer(serializers.ModelSerializer):
    """Read-only serializer for the locally-cached Clerk user record."""

    class Meta:
        model = ClerkUser
        fields = [
            'id',
            'clerk_user_id',
            'email',
            'full_name',
            'phone_number',
            'image_url',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields
