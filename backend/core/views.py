from datetime import timedelta
from django.utils import timezone
from django.db.models import Count
from django.db.models.functions import TruncMonth
from rest_framework import viewsets, status, permissions, generics, parsers
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

from .models import User, Document, Application, Notification, Service, ShareChecklist
from .serializers import (
    UserSerializer, UserListSerializer, DocumentSerializer,
    ApplicationSerializer, NotificationSerializer, ServiceSerializer,
    RegisterSerializer, LoginSerializer, ProfileSerializer,
    UserDocumentSerializer, UserApplicationSerializer,
    ShareChecklistSerializer, PublicChecklistSerializer,
)


class IsAdminUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_staff


# ══════════════════════════════════════════════════════════════
# ADMIN VIEWS
# ══════════════════════════════════════════════════════════════

class AdminDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]

    def get(self, request):
        now = timezone.now()
        thirty_days = now.date() + timedelta(days=30)

        total_users = User.objects.filter(is_staff=False).count()
        total_documents = Document.objects.count()
        total_applications = Application.objects.count()
        expiring_documents = Document.objects.filter(
            expiry_date__isnull=False,
            expiry_date__lte=thirty_days,
            expiry_date__gte=now.date(),
        ).count()
        pending_applications = Application.objects.filter(status='pending').count()

        recent_users = User.objects.filter(is_staff=False).order_by('-date_joined')[:5]

        six_months_ago = now - timedelta(days=180)
        user_growth_qs = (
            User.objects.filter(date_joined__gte=six_months_ago, is_staff=False)
            .annotate(month=TruncMonth('date_joined'))
            .values('month')
            .annotate(count=Count('id'))
            .order_by('month')
        )
        user_growth = [
            {'month': entry['month'].strftime('%b %Y'), 'count': entry['count']}
            for entry in user_growth_qs
        ]

        doc_uploads_qs = (
            Document.objects.filter(created_at__gte=six_months_ago)
            .annotate(month=TruncMonth('created_at'))
            .values('month')
            .annotate(count=Count('id'))
            .order_by('month')
        )
        document_uploads = [
            {'month': entry['month'].strftime('%b %Y'), 'count': entry['count']}
            for entry in doc_uploads_qs
        ]

        data = {
            'total_users': total_users,
            'total_documents': total_documents,
            'total_applications': total_applications,
            'expiring_documents': expiring_documents,
            'pending_applications': pending_applications,
            'recent_users': UserListSerializer(recent_users, many=True).data,
            'user_growth': user_growth,
            'document_uploads': document_uploads,
        }
        return Response(data)


class AdminUserViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = User.objects.filter(is_staff=False).order_by('-date_joined')
    serializer_class = UserSerializer
    http_method_names = ['get', 'delete']

    def get_serializer_class(self):
        if self.action == 'list':
            return UserListSerializer
        return UserSerializer


class AdminDocumentViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Document.objects.select_related('user').all()
    serializer_class = DocumentSerializer
    http_method_names = ['get', 'patch', 'delete']


class AdminApplicationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Application.objects.select_related('user', 'service').all()
    serializer_class = ApplicationSerializer
    http_method_names = ['get', 'patch', 'delete']

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        application = self.get_object()
        new_status = request.data.get('status')
        if new_status not in dict(Application.STATUS_CHOICES):
            return Response(
                {'error': 'Invalid status'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        application.status = new_status
        application.save()
        Notification.objects.create(
            user=application.user,
            title=f'Application {new_status.title()}',
            message=f'Your application {application.reference_number} for '
                    f'{application.service.name} has been {new_status}.',
            notification_type='application_update',
            is_admin=True,
        )
        return Response(ApplicationSerializer(application).data)


class AdminNotificationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = Notification.objects.filter(is_admin=True)
    serializer_class = NotificationSerializer
    http_method_names = ['get', 'patch', 'delete']

    @action(detail=True, methods=['patch'])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response(NotificationSerializer(notification).data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsAdminUser])
def check_expiring_documents(request):
    now = timezone.now()
    thirty_days = now.date() + timedelta(days=30)

    expiring_docs = Document.objects.filter(
        expiry_date__isnull=False,
        expiry_date__lte=thirty_days,
        expiry_date__gte=now.date(),
    )

    created_count = 0
    for doc in expiring_docs:
        doc.status = 'expiring'
        doc.save(update_fields=['status'])

        exists = Notification.objects.filter(
            user=doc.user,
            notification_type='expiry_warning',
            created_at__date=now.date(),
            message__contains=doc.document_number,
        ).exists()

        if not exists:
            days_left = (doc.expiry_date - now.date()).days
            Notification.objects.create(
                user=doc.user,
                title='Document Expiring Soon',
                message=f'{doc.get_document_type_display()} ({doc.document_number}) '
                        f'will expire in {days_left} days on {doc.expiry_date}.',
                notification_type='expiry_warning',
                is_admin=True,
            )
            created_count += 1

    expired_docs = Document.objects.filter(
        expiry_date__isnull=False,
        expiry_date__lt=now.date(),
    )
    expired_docs.update(status='expired')

    return Response({
        'expiring_documents': expiring_docs.count(),
        'notifications_created': created_count,
        'expired_documents_updated': expired_docs.count(),
    })


# ══════════════════════════════════════════════════════════════
# PUBLIC USER-FACING VIEWS
# ══════════════════════════════════════════════════════════════

def _get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'access': str(refresh.access_token),
        'refresh': str(refresh),
    }


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        tokens = _get_tokens_for_user(user)
        return Response({
            'message': 'User registered successfully.',
            'access': tokens['access'],
            'refresh': tokens['refresh'],
            'user': {
                'id': str(user.id),
                'email': user.email,
                'full_name': user.full_name,
            },
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']

        tokens = _get_tokens_for_user(user)
        return Response({
            'access': tokens['access'],
            'refresh': tokens['refresh'],
            'user': {
                'id': str(user.id),
                'email': user.email,
                'full_name': user.full_name,
                'phone_number': user.phone_number,
                'phone': user.phone,
                'address': user.address,
                'citizenship_number': user.citizenship_number,
                'is_verified': user.is_verified,
            },
        })

class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
            return Response({"detail": "Successfully logged out."}, status=status.HTTP_200_OK)
        except (TokenError, InvalidToken):
            return Response({"detail": "Token is invalid or expired."}, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ProfileSerializer

    def get_object(self):
        return self.request.user


class ServiceListView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = ServiceSerializer
    queryset = Service.objects.filter(is_active=True)


class UserDocumentViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserDocumentSerializer
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return Document.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserApplicationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserApplicationSerializer
    http_method_names = ['get', 'post']

    def get_queryset(self):
        return Application.objects.filter(user=self.request.user).select_related('service')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserNotificationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer
    http_method_names = ['get', 'patch']

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    @action(detail=True, methods=['patch'])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response(NotificationSerializer(notification).data)


class CreateShareChecklistView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        service_id = request.data.get('service_id')
        checklist_data = request.data.get('checklist_data', {})

        try:
            service = Service.objects.get(id=service_id)
        except Service.DoesNotExist:
            return Response({'error': 'Service not found'}, status=status.HTTP_404_NOT_FOUND)

        share_checklist = ShareChecklist.objects.create(
            user=request.user,
            service=service,
            checklist_data=checklist_data,
        )

        serializer = ShareChecklistSerializer(share_checklist, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class ShareChecklistListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ShareChecklistSerializer

    def get_queryset(self):
        return ShareChecklist.objects.filter(user=self.request.user)


class PublicShareChecklistView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, share_token):
        try:
            share_checklist = ShareChecklist.objects.get(share_token=share_token)
        except ShareChecklist.DoesNotExist:
            return Response({'error': 'Checklist not found or link expired'}, status=status.HTTP_404_NOT_FOUND)

        service = share_checklist.service
        checklist_items = share_checklist.checklist_data.get('items', [])
        checked_count = sum(1 for item in checklist_items if item.get('checked', False))
        total_count = len(checklist_items)

        data = {
            'service_title': service.name,
            'service_title_np': service.name_nepali,
            'checklist_items': checklist_items,
            'progress': f"{checked_count}/{total_count} completed",
            'shared_by': share_checklist.user.full_name,
            'created_at': share_checklist.created_at,
        }

        return Response(data)
