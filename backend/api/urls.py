from django.urls import path
from . import views

urlpatterns = [
    # Authentication endpoints
    path('auth/register/', views.register_user, name='register'),
    path('auth/login/', views.login_user, name='login'),
    
    # Plant family endpoints
    path('plant-families/', views.PlantFamilyList.as_view(), name='plant-family-list'),
    path('plant-families/<int:pk>/', views.PlantFamilyDetail.as_view(), name='plant-family-detail'),
    
    # Plant endpoints
    path('plants/', views.PlantList.as_view(), name='plant-list'),
    path('plants/<int:pk>/', views.PlantDetail.as_view(), name='plant-detail'),
    path('plants/by-family/<int:family_id>/', views.plants_by_family, name='plants-by-family'),
]