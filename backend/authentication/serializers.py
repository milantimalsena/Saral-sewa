from rest_framework import serializers
from authentication.models import ClerkUser, Document


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


class ClerkUserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating Clerk user profile."""

    class Meta:
        model = ClerkUser
        fields = ['full_name', 'phone_number', 'image_url']


class DocumentSerializer(serializers.ModelSerializer):
    """Serializer for document upload."""

    class Meta:
        model = Document
        fields = [
            'id',
            'document_type',
            'document_number',
            'expiry_date',
            'file',
            'file_name',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
