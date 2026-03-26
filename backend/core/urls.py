from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from . import views

# Admin router
admin_router = DefaultRouter()
admin_router.register(r'admin/users', views.AdminUserViewSet, basename='admin-users')
admin_router.register(r'admin/documents', views.AdminDocumentViewSet, basename='admin-documents')
admin_router.register(r'admin/applications', views.AdminApplicationViewSet, basename='admin-applications')
admin_router.register(r'admin/notifications', views.AdminNotificationViewSet, basename='admin-notifications')

# Public user router
user_router = DefaultRouter()
user_router.register(r'documents', views.UserDocumentViewSet, basename='user-documents')
user_router.register(r'applications', views.UserApplicationViewSet, basename='user-applications')
user_router.register(r'notifications', views.UserNotificationViewSet, basename='user-notifications')

urlpatterns = [
    # JWT Auth (SimpleJWT standard endpoints)
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Public auth endpoints (used by Flutter app)
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('services/', views.ServiceListView.as_view(), name='services'),

    # Admin dashboard
    path('admin/dashboard/', views.AdminDashboardView.as_view(), name='admin-dashboard'),
    path('admin/check-expiry/', views.check_expiring_documents, name='check-expiry'),

    # Share Checklist
    path('share/create/', views.CreateShareChecklistView.as_view(), name='create-share-checklist'),
    path('share/list/', views.ShareChecklistListView.as_view(), name='share-checklist-list'),
    path('share/public/<str:share_token>/', views.PublicShareChecklistView.as_view(), name='public-share-checklist'),

    # Router URLs (admin + user)
    path('', include(admin_router.urls)),
    path('', include(user_router.urls)),
]
