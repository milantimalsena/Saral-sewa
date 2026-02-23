from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse


def api_root(request):
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Saral Sewa API</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f2f5; color: #333; }
            .container { max-width: 720px; margin: 60px auto; padding: 0 20px; }
            h1 { font-size: 2rem; margin-bottom: 8px; color: #1a73e8; }
            .subtitle { color: #666; margin-bottom: 36px; font-size: 1.05rem; }
            .section { background: #fff; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); padding: 24px 28px; margin-bottom: 24px; }
            .section h2 { font-size: 1.1rem; color: #444; margin-bottom: 16px; border-bottom: 1px solid #eee; padding-bottom: 10px; }
            .link-list { list-style: none; }
            .link-list li { margin-bottom: 10px; }
            .link-list a { text-decoration: none; color: #1a73e8; font-size: 1rem; padding: 10px 16px; display: block; border-radius: 8px; transition: background 0.15s; }
            .link-list a:hover { background: #e8f0fe; }
            .link-list .method { display: inline-block; width: 54px; font-size: 0.75rem; font-weight: 700; color: #fff; background: #34a853; border-radius: 4px; text-align: center; padding: 2px 0; margin-right: 10px; vertical-align: middle; }
            .link-list .method.post { background: #ea8600; }
            .link-list .method.patch { background: #8e44ad; }
            .link-list .desc { color: #888; font-size: 0.85rem; margin-left: 64px; margin-top: 2px; }
            footer { text-align: center; color: #aaa; font-size: 0.85rem; margin-top: 40px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Saral Sewa API</h1>
            <p class="subtitle">Backend service for the Saral Sewa application</p>

            <div class="section">
                <h2>Admin</h2>
                <ul class="link-list">
                    <li><a href="/admin/"><span class="method">GET</span>/admin/</a>
                        <p class="desc">Django administration panel</p></li>
                </ul>
            </div>

            <div class="section">
                <h2>Authentication</h2>
                <ul class="link-list">
                    <li><a href="/api/register/"><span class="method post">POST</span>/api/register/</a>
                        <p class="desc">Register a new user account</p></li>
                    <li><a href="/api/login/"><span class="method post">POST</span>/api/login/</a>
                        <p class="desc">Login and obtain JWT tokens</p></li>
                    <li><a href="/api/logout/"><span class="method post">POST</span>/api/logout/</a>
                        <p class="desc">Logout and blacklist refresh token</p></li>
                </ul>
            </div>

            <div class="section">
                <h2>User Profile</h2>
                <ul class="link-list">
                    <li><a href="/api/profile/"><span class="method">GET</span>/api/profile/</a>
                        <p class="desc">Get current user profile</p></li>
                    <li><a href="/api/profile/update/"><span class="method patch">PATCH</span>/api/profile/update/</a>
                        <p class="desc">Update user profile</p></li>
                </ul>
            </div>

            <div class="section">
                <h2>Password Management</h2>
                <ul class="link-list">
                    <li><a href="/api/password-change/"><span class="method post">POST</span>/api/password-change/</a>
                        <p class="desc">Change password (authenticated)</p></li>
                    <li><a href="/api/password-reset-request/"><span class="method post">POST</span>/api/password-reset-request/</a>
                        <p class="desc">Request password reset email</p></li>
                    <li><a href="/api/password-reset/"><span class="method post">POST</span>/api/password-reset/</a>
                        <p class="desc">Reset password with token</p></li>
                </ul>
            </div>

            <div class="section">
                <h2>Token Management</h2>
                <ul class="link-list">
                    <li><a href="/api/token/refresh/"><span class="method post">POST</span>/api/token/refresh/</a>
                        <p class="desc">Refresh an access token</p></li>
                    <li><a href="/api/verify-token/"><span class="method">GET</span>/api/verify-token/</a>
                        <p class="desc">Verify current access token</p></li>
                </ul>
            </div>

            <footer>Saral Sewa &mdash; Django REST Framework Backend</footer>
        </div>
    </body>
    </html>
    """
    return HttpResponse(html)


urlpatterns = [
    path('', api_root, name='api-root'),
    path('admin/', admin.site.urls),
    path('api/', include('authentication.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
