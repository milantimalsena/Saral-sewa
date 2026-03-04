from django.urls import path
from authentication.views import (
    UserProfileView,
    VerifyTokenView,
    HealthCheckView,
)

urlpatterns = [
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('verify-token/', VerifyTokenView.as_view(), name='verify_token'),
    path('health/', HealthCheckView.as_view(), name='health'),
]
