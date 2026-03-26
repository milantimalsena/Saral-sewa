from django.contrib.auth import authenticate
from rest_framework import serializers
from .models import User, Document, Application, Notification, Service, ShareChecklist


class UserSerializer(serializers.ModelSerializer):
    documents_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number',
            'phone', 'address', 'citizenship_number', 'is_verified',
            'is_active', 'date_joined', 'created_at', 'documents_count',
        ]

    def get_documents_count(self, obj):
        return obj.documents.count()


class UserListSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'phone_number', 'phone', 'date_joined', 'is_active']


class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = '__all__'


class DocumentSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    computed_status = serializers.ReadOnlyField()
    document_type_display = serializers.SerializerMethodField()
    document_file_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Document
        fields = [
            'id', 'user', 'user_name', 'document_type', 'document_type_display',
            'document_number', 'issue_date', 'expiry_date', 'document_file', 'document_file_url', 'status',
            'computed_status', 'notes', 'created_at', 'updated_at',
        ]

    def get_user_name(self, obj):
        return obj.user.full_name or obj.user.email

    def get_document_type_display(self, obj):
        return obj.get_document_type_display()

    def get_document_file_url(self, obj):
        request = self.context.get('request')
        if obj.document_file and request:
            return request.build_absolute_uri(obj.document_file.url)
        return None


class ApplicationSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    service_name = serializers.SerializerMethodField()
    status_display = serializers.SerializerMethodField()

    class Meta:
        model = Application
        fields = [
            'id', 'user', 'user_name', 'service', 'service_name',
            'status', 'status_display', 'reference_number', 'remarks',
            'submitted_at', 'updated_at',
        ]

    def get_user_name(self, obj):
        return obj.user.full_name or obj.user.email

    def get_service_name(self, obj):
        return obj.service.name

    def get_status_display(self, obj):
        return obj.get_status_display()


class NotificationSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    type_display = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'user_name', 'title', 'message',
            'notification_type', 'type_display', 'is_read',
            'is_admin', 'created_at',
        ]

    def get_user_name(self, obj):
        if obj.user:
            return obj.user.full_name or obj.user.email
        return 'System'

    def get_type_display(self, obj):
        return obj.get_notification_type_display()


class DashboardSerializer(serializers.Serializer):
    total_users = serializers.IntegerField()
    total_documents = serializers.IntegerField()
    total_applications = serializers.IntegerField()
    expiring_documents = serializers.IntegerField()
    pending_applications = serializers.IntegerField()
    recent_users = UserListSerializer(many=True)
    user_growth = serializers.ListField()
    document_uploads = serializers.ListField()


# ═══════════════════════════════════════════════════════════
# PUBLIC USER-FACING SERIALIZERS
# ═══════════════════════════════════════════════════════════


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)
    full_name = serializers.CharField(max_length=255)
    phone_number = serializers.CharField(max_length=20, required=False, default='')

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            full_name=validated_data['full_name'],
            phone_number=validated_data.get('phone_number', ''),
        )
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        email = data.get('email')
        password = data.get('password')

        user = authenticate(email=email, password=password)
        if user is None:
            raise serializers.ValidationError('Invalid email or password.')
        if not user.is_active:
            raise serializers.ValidationError('This account has been disabled.')

        data['user'] = user
        return data


class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone_number', 
            'phone', 'address', 'citizenship_number', 'is_verified', 'date_joined'
        ]
        read_only_fields = ['id', 'email', 'is_verified', 'date_joined']


class UserDocumentSerializer(serializers.ModelSerializer):
    document_type_display = serializers.SerializerMethodField(read_only=True)
    computed_status = serializers.ReadOnlyField()
    document_file_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Document
        fields = [
            'id', 'document_type', 'document_type_display', 'document_number',
            'issue_date', 'expiry_date', 'document_file', 'document_file_url', 'status', 'computed_status',
            'notes', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'status', 'computed_status', 'created_at', 'updated_at']
        extra_kwargs = {
            'document_file': {'required': True},
        }

    def get_document_type_display(self, obj):
        return obj.get_document_type_display()

    def get_document_file_url(self, obj):
        request = self.context.get('request')
        if obj.document_file and request:
            return request.build_absolute_uri(obj.document_file.url)
        return None


class UserApplicationSerializer(serializers.ModelSerializer):
    service_name = serializers.SerializerMethodField(read_only=True)
    status_display = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Application
        fields = [
            'id', 'service', 'service_name', 'status', 'status_display',
            'reference_number', 'remarks', 'submitted_at', 'updated_at',
        ]
        read_only_fields = ['id', 'status', 'reference_number', 'submitted_at', 'updated_at']

    def get_service_name(self, obj):
        return obj.service.name

    def get_status_display(self, obj):
        return obj.get_status_display()

class ShareChecklistSerializer(serializers.ModelSerializer):
    service_name = serializers.CharField(source='service.name', read_only=True)
    service_title_np = serializers.CharField(source='service.name_nepali', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    share_url = serializers.SerializerMethodField()

    class Meta:
        model = ShareChecklist
        fields = [
            'id', 'share_token', 'share_url', 'service', 'service_name',
            'service_title_np', 'user_email', 'checklist_data', 'created_at', 'expires_at',
        ]
        read_only_fields = ['id', 'share_token', 'created_at']

    def get_share_url(self, obj):
        request = self.context.get('request')
        if request:
            domain = request.get_host()
            return f"https://{domain}/share/checklist/{obj.share_token}/"
        return f"/share/checklist/{obj.share_token}/"


class PublicChecklistSerializer(serializers.Serializer):
    service_title = serializers.CharField()
    service_title_np = serializers.CharField()
    checklist_items = serializers.ListField()
    progress = serializers.CharField()
    shared_by = serializers.CharField()
    created_at = serializers.DateTimeField()