from django.shortcuts import render, get_object_or_404
from rest_framework import status, generics, viewsets, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate
from django.db.models import Sum, Count
from rest_framework_simplejwt.tokens import RefreshToken
from django_filters.rest_framework import DjangoFilterBackend
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from .models import (
    PlantLocation, Profile, Category, Post,
    PlantFamily, Plant,
    MaleFlower, FemaleFlower, HermaphroditeFlower, PlantSubmission
)
from .serializers import (
    PlantLocationSerializer, UserRegistrationSerializer, UserLoginSerializer,
    PlantFamilySerializer, PlantListSerializer, PlantDetailSerializer,
    PlantSubmissionSerializer, MaleFlowerSubmissionSerializer,
    FemaleFlowerSubmissionSerializer, HermaphroditeFlowerSubmissionSerializer
)
from django.db import models

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
    filter_backends = [DjangoFilterBackend,
                       filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['family', 'cotyledon_type',
                        'flower_type', 'classification']
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


# Define example request bodies for Swagger documentation
both_flower_example = {
    "name_arabic": "نبات العينة",
    "name_english": "Sample Plant",
    "name_scientific": "Plantus exampleus",
    "family": 1,
    "classification": "اقتصادي",
    "seed_shape_arabic": "مستدير",
    "seed_shape_english": "Round",
    "cotyledon_type": "MONO",
    "flower_type": "BOTH",
    "male_flower": {
        "sepal_arrangement": "RANGE",
        "sepal_range_min": 4,
        "sepal_range_max": 6,
        "sepals_fused": False,
        "petal_arrangement": "RANGE",
        "petal_range_min": 4,
        "petal_range_max": 6,
        "petals_fused": False,
        "stamens": "5-10 stamens arranged in a whorl"
    },
    "female_flower": {
        "sepal_arrangement": "RANGE",
        "sepal_range_min": 4,
        "sepal_range_max": 6,
        "sepals_fused": False,
        "petal_arrangement": "RANGE",
        "petal_range_min": 4,
        "petal_range_max": 6,
        "petals_fused": False,
        "carpels": "3-5 carpels fused into a compound pistil"
    }
}

hermaphrodite_flower_example = {
    "name_arabic": "نبات خنثى",
    "name_english": "Hermaphrodite Plant",
    "name_scientific": "Plantus hermaphroditus",
    "family": 2,
    "classification": "بري",
    "seed_shape_arabic": "بيضاوي",
    "seed_shape_english": "Oval",
    "cotyledon_type": "DI",
    "flower_type": "HERMAPHRODITE",
    "hermaphrodite_flower": {
        "sepal_arrangement": "RANGE",
        "sepal_range_min": 5,
        "sepal_range_max": 5,
        "sepals_fused": True,
        "petal_arrangement": "RANGE",
        "petal_range_min": 5,
        "petal_range_max": 5,
        "petals_fused": True,
        "stamens": "Multiple stamens in clusters",
        "carpels": "Compound ovary with multiple carpels"
    }
}


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@swagger_auto_schema(
    request_body=PlantSubmissionSerializer,
    operation_description="Submit a new plant for review. The request body should include plant details including description, flower characteristics based on the flower_type, and optional images.",
    responses={201: PlantSubmissionSerializer()},
    examples={
        'application/json': {
            'Both male and female flowers': both_flower_example,
            'Hermaphrodite flower': hermaphrodite_flower_example
        }
    }
)
def submit_plant(request):
    """
    Endpoint for users to submit plant data for review.

    Required fields:
    - name_arabic: Plant name in Arabic
    - name_scientific: Scientific name of the plant
    - family: ID of the plant family
    - classification: Plant classification (e.g., 'بري', 'اقتصادي')
    - seed_shape_arabic: Description of seed shape in Arabic
    - cotyledon_type: 'MONO' for monocotyledon or 'DI' for dicotyledon
    - flower_type: 'BOTH' for plants with separate male and female flowers, 'HERMAPHRODITE' for plants with hermaphrodite flowers

    Optional fields:
    - name_english: Plant name in English
    - description: Detailed description of the plant
    - seed_shape_english: Description of seed shape in English
    - images: List of image files for the plant
    - image_captions: List of captions for the images (must match length of images list)

    Based on flower_type, include either:
    - male_flower and female_flower (when flower_type is 'BOTH')
    - hermaphrodite_flower (when flower_type is 'HERMAPHRODITE')
    """
    serializer = PlantSubmissionSerializer(
        data=request.data, context={'request': request})
    if serializer.is_valid():
        submission = serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
def search_plants(request):
    """
    Search for plants by name (Arabic, English, Scientific) or classification

    Query parameters:
    - q: General search term for either name or classification
    - name: Search specifically in plant names (Arabic, English, Scientific)
    - classification: Filter specifically by classification type
    """
    # General search parameter that searches across name and classification
    query = request.query_params.get('q', '')

    # Specific search parameters
    name_query = request.query_params.get('name', '')
    classification = request.query_params.get('classification', '')

    queryset = Plant.objects.all()

    # If general query parameter is provided, search across all fields
    if query:
        queryset = queryset.filter(
            models.Q(name_arabic__icontains=query) |
            models.Q(name_english__icontains=query) |
            models.Q(name_scientific__icontains=query) |
            models.Q(classification__icontains=query)
        )

    # If specific name query is provided
    if name_query:
        queryset = queryset.filter(
            models.Q(name_arabic__icontains=name_query) |
            models.Q(name_english__icontains=name_query) |
            models.Q(name_scientific__icontains=name_query)
        )

    # If specific classification filter is provided
    if classification:
        queryset = queryset.filter(classification__icontains=classification)

    # Use the existing PlantListSerializer
    serializer = PlantListSerializer(
        queryset, many=True, context={'request': request})
    return Response(serializer.data)


class PlantLocationList(generics.ListCreateAPIView):
    """API view to create and list plant locations"""
    serializer_class = PlantLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['plant']
    search_fields = ['plant__name_arabic', 'plant__name_english', 'plant__name_scientific', 'notes']
    ordering_fields = ['created_at', 'quantity']
    
    def get_queryset(self):
        """Return locations submitted by the authenticated user"""
        return PlantLocation.objects.filter(user=self.request.user)

class PlantLocationDetail(generics.RetrieveUpdateDestroyAPIView):
    """API view to retrieve, update or delete a plant location"""
    serializer_class = PlantLocationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return locations submitted by the authenticated user"""
        return PlantLocation.objects.filter(user=self.request.user)

# Add this function-based view for retrieving all locations for a specific plant
@api_view(['GET'])
@permission_classes([AllowAny])
def plant_locations_by_plant(request, plant_id):
    """Get all locations for a specific plant"""
    locations = PlantLocation.objects.filter(plant_id=plant_id)
    # Aggregate the total quantity across all locations
    total_count = locations.aggregate(total=Sum('quantity'))['total'] or 0
    # Count the number of unique users who have spotted this plant
    unique_users = locations.values('user').distinct().count()
    
    serializer = PlantLocationSerializer(
        locations, many=True, context={'request': request}
    )
    return Response({
        'total_locations': locations.count(),
        'total_plants_found': total_count,
        'unique_spotters': unique_users,
        'locations': serializer.data
    })

# Add this function-based view for user stats
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_location_stats(request):
    """Get statistics for the authenticated user's plant locations"""
    user_locations = PlantLocation.objects.filter(user=request.user)
    total_plants = user_locations.aggregate(total=Sum('quantity'))['total'] or 0
    unique_plants = user_locations.values('plant').distinct().count()
    
    # Get most recent locations
    recent_locations = user_locations.order_by('-created_at')[:5]
    recent_serializer = PlantLocationSerializer(
        recent_locations, many=True, context={'request': request}
    )
    
    # Get plants by count (most spotted)
    plant_counts = user_locations.values('plant', 'plant__name_arabic') \
        .annotate(count=Sum('quantity')) \
        .order_by('-count')[:5]
    
    return Response({
        'total_locations': user_locations.count(),
        'total_plants_found': total_plants,
        'unique_plants': unique_plants,
        'recent_locations': recent_serializer.data,
        'most_spotted_plants': plant_counts
    })