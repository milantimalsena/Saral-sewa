from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse


def root_status(_request):
    return JsonResponse({
        'message': 'Saral Sewa backend is running.',
        'api': '/api/',
        'admin': '/django-admin/',
    })

urlpatterns = [
    path('', root_status, name='root-status'),
    path('health/', root_status, name='health'),
    path('django-admin/', admin.site.urls),
    path('api/', include('core.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
