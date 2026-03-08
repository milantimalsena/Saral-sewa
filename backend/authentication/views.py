from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.views import APIView

from authentication.models import ClerkUser, Document
from authentication.serializers import ClerkUserSerializer, ClerkUserUpdateSerializer, DocumentSerializer


class UserProfileView(generics.RetrieveAPIView):
    """Return the current Clerk user's cached profile."""
    serializer_class = ClerkUserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserProfileUpdateView(generics.UpdateAPIView):
    """Update the current user's profile."""
    serializer_class = ClerkUserUpdateSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class DocumentListView(generics.ListCreateAPIView):
    """List all documents or create a new document for the user."""
    serializer_class = DocumentSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        return Document.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class DocumentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update or delete a document."""
    serializer_class = DocumentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Document.objects.filter(user=self.request.user)


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
