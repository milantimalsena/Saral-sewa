from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView as SimpleJWTTokenRefreshView
from authentication.views import (
    UserRegistrationView,
    CustomTokenObtainPairView,
    UserProfileView,
    PasswordChangeView,
    PasswordResetRequestView,
    PasswordResetView,
    LogoutView,
    TokenRefreshView,
    VerifyTokenView
)

urlpatterns = [
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('profile/update/', UserProfileView.as_view(), name='profile_update'),
    path('password-change/', PasswordChangeView.as_view(), name='password_change'),
    path('password-reset-request/', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password-reset/', PasswordResetView.as_view(), name='password_reset'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('verify-token/', VerifyTokenView.as_view(), name='verify_token'),
]
