from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from authentication.views import (
    UserProfileView,
    UserProfileUpdateView,
    DocumentListView,
    DocumentDetailView,
    SimpleLoginView,
    SimpleRegisterView,
    VerifyTokenView,
    HealthCheckView,
)

urlpatterns = [
    path('login/', SimpleLoginView.as_view(), name='simple-login'),
    path('register/', SimpleRegisterView.as_view(), name='simple-register'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('profile/update/', UserProfileUpdateView.as_view(), name='profile-update'),
    path('documents/', DocumentListView.as_view(), name='documents-list'),
    path('documents/<uuid:pk>/', DocumentDetailView.as_view(), name='documents-detail'),
    path('verify-token/', VerifyTokenView.as_view(), name='verify_token'),
    path('health/', HealthCheckView.as_view(), name='health'),
]
