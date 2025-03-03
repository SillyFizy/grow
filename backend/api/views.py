from django.shortcuts import render, get_object_or_404
from rest_framework import status, generics, viewsets, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from django_filters.rest_framework import DjangoFilterBackend
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from .models import (
    Profile, Category, Post, 
    PlantFamily, Plant,
    MaleFlower, FemaleFlower, HermaphroditeFlower
)
from .serializers import (
    UserRegistrationSerializer, UserLoginSerializer,
    PlantFamilySerializer, PlantListSerializer, PlantDetailSerializer
)

# Authentication views
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    serializer = UserLoginSerializer(data=request.data)
    if serializer.is_valid():
        user = authenticate(
            username=serializer.validated_data['username'],
            password=serializer.validated_data['password']
        )
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            })
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Plant Family views
class PlantFamilyList(generics.ListAPIView):
    queryset = PlantFamily.objects.all()
    serializer_class = PlantFamilySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name_arabic', 'name_english', 'name_scientific']
    ordering_fields = ['name_arabic', 'name_english']

class PlantFamilyDetail(generics.RetrieveAPIView):
    queryset = PlantFamily.objects.all()
    serializer_class = PlantFamilySerializer
    permission_classes = [AllowAny]

# Plant views
class PlantList(generics.ListAPIView):
    queryset = Plant.objects.all()
    serializer_class = PlantListSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['family', 'cotyledon_type', 'flower_type', 'classification']
    search_fields = ['name_arabic', 'name_english', 'name_scientific']
    ordering_fields = ['id', 'name_arabic', 'name_scientific']

class PlantDetail(generics.RetrieveAPIView):
    queryset = Plant.objects.all()
    serializer_class = PlantDetailSerializer
    permission_classes = [AllowAny]

@api_view(['GET'])
@permission_classes([AllowAny])
def plants_by_family(request, family_id):
    """Get all plants belonging to a specific family"""
    plants = Plant.objects.filter(family_id=family_id)
    serializer = PlantListSerializer(plants, many=True)
    return Response(serializer.data)