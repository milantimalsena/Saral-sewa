"""
Clerk JWT Authentication for Django REST Framework.

Verifies JWTs issued by Clerk and maps them to local ClerkUser records.
Configure CLERK_FRONTEND_API and CLERK_SECRET_KEY in your Django settings
or .env file.
"""

import time
import jwt
import requests
from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

# Cache JWKS for 10 minutes to avoid hitting Clerk on every request
_jwks_cache = {'keys': None, 'fetched_at': 0}
JWKS_CACHE_TTL = 600  # seconds


def _get_jwks():
    """Fetch and cache Clerk's JWKS (JSON Web Key Set)."""
    now = time.time()
    if _jwks_cache['keys'] and (now - _jwks_cache['fetched_at']) < JWKS_CACHE_TTL:
        return _jwks_cache['keys']

    clerk_frontend_api = getattr(settings, 'CLERK_FRONTEND_API', '')
    if not clerk_frontend_api:
        raise AuthenticationFailed('CLERK_FRONTEND_API is not configured.')

    jwks_url = f"https://{clerk_frontend_api}/.well-known/jwks.json"

    try:
        response = requests.get(jwks_url, timeout=5)
        response.raise_for_status()
        jwks = response.json()
        _jwks_cache['keys'] = jwks.get('keys', [])
        _jwks_cache['fetched_at'] = now
        return _jwks_cache['keys']
    except requests.RequestException as e:
        raise AuthenticationFailed(f'Failed to fetch Clerk JWKS: {e}')


def _get_signing_key(token):
    """Find the RSA public key matching the token's kid."""
    keys = _get_jwks()
    unverified_header = jwt.get_unverified_header(token)
    kid = unverified_header.get('kid')

    for key_data in keys:
        if key_data.get('kid') == kid:
            return jwt.algorithms.RSAAlgorithm.from_jwk(key_data)

    raise AuthenticationFailed('No matching signing key found in Clerk JWKS.')


class ClerkJWTAuthentication(BaseAuthentication):
    """
    DRF authentication backend that verifies Clerk-issued JWTs.

    Usage:
      - Set CLERK_FRONTEND_API in settings.py (e.g., 'your-app.clerk.accounts.dev')
      - Clients send: Authorization: Bearer <clerk_session_jwt>
      - On success, request.user is a ClerkUser instance
    """

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if not auth_header.startswith('Bearer '):
            return None

        token = auth_header[7:]

        try:
            rsa_key = _get_signing_key(token)

            payload = jwt.decode(
                token,
                rsa_key,
                algorithms=['RS256'],
                options={
                    'verify_aud': False,
                    'verify_iss': True,
                },
                issuer=f"https://{settings.CLERK_FRONTEND_API}",
            )

            clerk_user_id = payload.get('sub')
            if not clerk_user_id:
                raise AuthenticationFailed('Token missing subject claim.')

            # Import here to avoid circular imports
            from authentication.models import ClerkUser

            user, created = ClerkUser.objects.get_or_create(
                clerk_user_id=clerk_user_id,
                defaults={
                    'email': payload.get('email', ''),
                    'full_name': payload.get('name', ''),
                }
            )

            # Update cached user data if it changed
            if not created:
                updated = False
                email = payload.get('email', '')
                name = payload.get('name', '')
                if email and email != user.email:
                    user.email = email
                    updated = True
                if name and name != user.full_name:
                    user.full_name = name
                    updated = True
                if updated:
                    user.save()

            return (user, token)

        except jwt.ExpiredSignatureError:
            raise AuthenticationFailed('Clerk session token has expired.')
        except jwt.InvalidTokenError as e:
            raise AuthenticationFailed(f'Invalid Clerk token: {e}')

    def authenticate_header(self, request):
        return 'Bearer'
