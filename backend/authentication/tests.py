from __future__ import annotations

from unittest.mock import Mock, patch

from django.test import TestCase, override_settings
from rest_framework.test import APIRequestFactory

from authentication.models import ClerkUser


class ClerkJWTAuthenticationTests(TestCase):
    def setUp(self):
        # Reset module-level JWKS cache between tests to avoid cross-test coupling.
        from authentication import clerk_auth

        clerk_auth._jwks_cache["keys"] = None
        clerk_auth._jwks_cache["fetched_at"] = 0

    def test_authenticate_returns_none_without_bearer_header(self):
        from authentication.clerk_auth import ClerkJWTAuthentication

        request = APIRequestFactory().get("/api/verify-token/")
        result = ClerkJWTAuthentication().authenticate(request)
        self.assertIsNone(result)

    @override_settings(CLERK_FRONTEND_API="example.clerk.accounts.dev")
    def test_authenticate_creates_user_and_returns_user_and_token(self):
        from authentication.clerk_auth import ClerkJWTAuthentication

        payload = {"sub": "user_123", "email": "a@example.com", "name": "Alice"}

        with patch("authentication.clerk_auth._get_signing_key", return_value=object()), patch(
            "authentication.clerk_auth.jwt.decode", return_value=payload
        ):
            request = APIRequestFactory().get(
                "/api/verify-token/",
                HTTP_AUTHORIZATION="Bearer test.token.value",
            )

            user, token = ClerkJWTAuthentication().authenticate(request)

        self.assertEqual(token, "test.token.value")
        self.assertIsInstance(user, ClerkUser)
        self.assertEqual(user.clerk_user_id, "user_123")
        self.assertEqual(user.email, "a@example.com")
        self.assertEqual(user.full_name, "Alice")

    @override_settings(CLERK_FRONTEND_API="example.clerk.accounts.dev")
    def test_authenticate_updates_cached_user_fields(self):
        from authentication.clerk_auth import ClerkJWTAuthentication

        ClerkUser.objects.create(
            clerk_user_id="user_123",
            email="old@example.com",
            full_name="Old Name",
        )

        payload = {"sub": "user_123", "email": "new@example.com", "name": "New Name"}

        with patch("authentication.clerk_auth._get_signing_key", return_value=object()), patch(
            "authentication.clerk_auth.jwt.decode", return_value=payload
        ):
            request = APIRequestFactory().get(
                "/api/verify-token/",
                HTTP_AUTHORIZATION="Bearer test.token.value",
            )
            user, _token = ClerkJWTAuthentication().authenticate(request)

        user.refresh_from_db()
        self.assertEqual(user.email, "new@example.com")
        self.assertEqual(user.full_name, "New Name")

    @override_settings(CLERK_FRONTEND_API="example.clerk.accounts.dev")
    def test_authenticate_raises_on_expired_token(self):
        from authentication.clerk_auth import ClerkJWTAuthentication
        import jwt
        from rest_framework.exceptions import AuthenticationFailed

        with patch("authentication.clerk_auth._get_signing_key", return_value=object()), patch(
            "authentication.clerk_auth.jwt.decode", side_effect=jwt.ExpiredSignatureError()
        ):
            request = APIRequestFactory().get(
                "/api/verify-token/",
                HTTP_AUTHORIZATION="Bearer test.token.value",
            )
            with self.assertRaises(AuthenticationFailed):
                ClerkJWTAuthentication().authenticate(request)

    @override_settings(CLERK_FRONTEND_API="example.clerk.accounts.dev")
    def test_authenticate_raises_on_invalid_token(self):
        from authentication.clerk_auth import ClerkJWTAuthentication
        import jwt
        from rest_framework.exceptions import AuthenticationFailed

        with patch("authentication.clerk_auth._get_signing_key", return_value=object()), patch(
            "authentication.clerk_auth.jwt.decode", side_effect=jwt.InvalidTokenError("nope")
        ):
            request = APIRequestFactory().get(
                "/api/verify-token/",
                HTTP_AUTHORIZATION="Bearer test.token.value",
            )
            with self.assertRaises(AuthenticationFailed):
                ClerkJWTAuthentication().authenticate(request)

    def test_get_jwks_requires_clerk_frontend_api(self):
        from authentication.clerk_auth import _get_jwks
        from rest_framework.exceptions import AuthenticationFailed

        with override_settings(CLERK_FRONTEND_API=""):
            with self.assertRaises(AuthenticationFailed):
                _get_jwks()

    @override_settings(CLERK_FRONTEND_API="example.clerk.accounts.dev")
    def test_get_jwks_is_cached_for_ttl(self):
        from authentication import clerk_auth

        # First call hits requests.get; second call should be served from cache.
        fake_response = Mock()
        fake_response.raise_for_status = Mock()
        fake_response.json.return_value = {"keys": [{"kid": "kid1"}]}

        with patch("authentication.clerk_auth.requests.get", return_value=fake_response) as get_mock, patch(
            "authentication.clerk_auth.time.time", side_effect=[1000.0, 1001.0]
        ):
            keys1 = clerk_auth._get_jwks()
            keys2 = clerk_auth._get_jwks()

        self.assertEqual(keys1, [{"kid": "kid1"}])
        self.assertEqual(keys2, [{"kid": "kid1"}])
        self.assertEqual(get_mock.call_count, 1)

    @override_settings(CLERK_FRONTEND_API="example.clerk.accounts.dev")
    def test_get_signing_key_selects_matching_kid(self):
        from authentication import clerk_auth

        token = "test.token.value"

        with patch("authentication.clerk_auth._get_jwks", return_value=[{"kid": "kid123"}]), patch(
            "authentication.clerk_auth.jwt.get_unverified_header", return_value={"kid": "kid123"}
        ), patch(
            "authentication.clerk_auth.jwt.algorithms.RSAAlgorithm.from_jwk",
            return_value="PUBLIC_KEY",
        ) as from_jwk_mock:
            key = clerk_auth._get_signing_key(token)

        self.assertEqual(key, "PUBLIC_KEY")
        from_jwk_mock.assert_called_once()
