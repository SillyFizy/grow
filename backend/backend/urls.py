from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# Schema view for Swagger documentation (updated)
schema_view = get_schema_view(
    openapi.Info(
        title="Plant API",
        default_version='v1',
        description="API documentation for Plant Classification Backend",
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
    url=settings.API_URL if hasattr(settings, 'API_URL') else None,  # Set base URL if configured
    patterns=[path('api/', include('api.urls'))],  # This tells Swagger where to find the API endpoints
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    
    # Swagger documentation URLs
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)