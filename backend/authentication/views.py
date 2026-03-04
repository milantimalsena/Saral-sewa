from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny

from authentication.models import ClerkUser
from authentication.serializers import ClerkUserSerializer


class UserProfileView(generics.RetrieveAPIView):
    """Return the current Clerk user's cached profile."""
    serializer_class = ClerkUserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class VerifyTokenView(generics.GenericAPIView):
    """Verify that the Clerk session token is valid."""
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response({
            'message': 'Token is valid.',
            'user': ClerkUserSerializer(request.user).data
        }, status=status.HTTP_200_OK)


class HealthCheckView(generics.GenericAPIView):
    """Public health-check endpoint."""
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request, *args, **kwargs):
        return Response({'status': 'ok'}, status=status.HTTP_200_OK)
