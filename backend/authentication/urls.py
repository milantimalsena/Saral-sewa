from django.urls import path
from authentication.views import (
    UserProfileView,
    UserProfileUpdateView,
    DocumentListView,
    DocumentDetailView,
    VerifyTokenView,
    HealthCheckView,
)

urlpatterns = [
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('profile/update/', UserProfileUpdateView.as_view(), name='profile-update'),
    path('documents/', DocumentListView.as_view(), name='documents-list'),
    path('documents/<uuid:pk>/', DocumentDetailView.as_view(), name='documents-detail'),
    path('verify-token/', VerifyTokenView.as_view(), name='verify_token'),
    path('health/', HealthCheckView.as_view(), name='health'),
]
