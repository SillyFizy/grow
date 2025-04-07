from django.urls import path
from . import views
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
    TokenBlacklistView,
)

urlpatterns = [

    # JWT Token endpoints
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('auth/token/blacklist/',
         TokenBlacklistView.as_view(), name='token_blacklist'),

    # Authentication endpoints
    path('auth/register/', views.register_user, name='register'),
    path('auth/login/', views.login_user, name='login'),

    # Plant family endpoints
    path('plant-families/', views.PlantFamilyList.as_view(),
         name='plant-family-list'),
    path('plant-families/<int:pk>/', views.PlantFamilyDetail.as_view(),
         name='plant-family-detail'),

    # Plant endpoints
    path('plants/', views.PlantList.as_view(), name='plant-list'),
    path('plants/<int:pk>/', views.PlantDetail.as_view(), name='plant-detail'),
    path('plants/by-family/<int:family_id>/',
         views.plants_by_family, name='plants-by-family'),

    # Plant submission endpoint
    path('plants/submit/', views.submit_plant, name='submit-plant'),

    # Search endpoint
    path('plants/search/', views.search_plants, name='search-plants'),

    # Plant location endpoints
    path('plant-locations/', views.PlantLocationList.as_view(),
         name='plant-location-list'),
    path('plant-locations/<int:pk>/', views.PlantLocationDetail.as_view(),
         name='plant-location-detail'),
    path('plants/<int:plant_id>/locations/',
         views.plant_locations_by_plant, name='plant-locations-by-plant'),
    path('users/me/location-stats/', views.user_location_stats,
         name='user-location-stats'),
]
