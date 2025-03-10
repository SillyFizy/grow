from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from .models import (
    Profile, Category, Post, 
    PlantFamily, Plant,
    MaleFlower, FemaleFlower, HermaphroditeFlower
)

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('username', 'password', 'password2')

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password']
        )
        return user

class UserLoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

# Plant serializers
class PlantFamilySerializer(serializers.ModelSerializer):
    """Plant family serializer with complete details"""
    
    class Meta:
        model = PlantFamily
        fields = '__all__'

class MaleFlowerSerializer(serializers.ModelSerializer):
    """Serializer for male flower characteristics"""
    
    sepal_arrangement = serializers.CharField(help_text="Type of sepal arrangement (NONE, RANGE, INDEFINITE)")
    sepal_range_min = serializers.IntegerField(help_text="Minimum number of sepals", allow_null=True)
    sepal_range_max = serializers.IntegerField(help_text="Maximum number of sepals", allow_null=True)
    sepals_fused = serializers.BooleanField(help_text="Whether sepals are fused (gamosepalous)")
    petal_arrangement = serializers.CharField(help_text="Type of petal arrangement (NONE, RANGE, INDEFINITE)")
    petal_range_min = serializers.IntegerField(help_text="Minimum number of petals", allow_null=True)
    petal_range_max = serializers.IntegerField(help_text="Maximum number of petals", allow_null=True)
    petals_fused = serializers.BooleanField(help_text="Whether petals are fused")
    stamens = serializers.CharField(help_text="Description of stamens")
    
    class Meta:
        model = MaleFlower
        exclude = ('plant',)

class FemaleFlowerSerializer(serializers.ModelSerializer):
    """Serializer for female flower characteristics"""
    
    sepal_arrangement = serializers.CharField(help_text="Type of sepal arrangement (NONE, RANGE, INDEFINITE)")
    sepal_range_min = serializers.IntegerField(help_text="Minimum number of sepals", allow_null=True)
    sepal_range_max = serializers.IntegerField(help_text="Maximum number of sepals", allow_null=True)
    sepals_fused = serializers.BooleanField(help_text="Whether sepals are fused (gamosepalous)")
    petal_arrangement = serializers.CharField(help_text="Type of petal arrangement (NONE, RANGE, INDEFINITE)")
    petal_range_min = serializers.IntegerField(help_text="Minimum number of petals", allow_null=True)
    petal_range_max = serializers.IntegerField(help_text="Maximum number of petals", allow_null=True)
    petals_fused = serializers.BooleanField(help_text="Whether petals are fused")
    carpels = serializers.CharField(help_text="Description of carpels")
    
    class Meta:
        model = FemaleFlower
        exclude = ('plant',)

class HermaphroditeFlowerSerializer(serializers.ModelSerializer):
    """Serializer for hermaphrodite flower characteristics"""
    
    sepal_arrangement = serializers.CharField(help_text="Type of sepal arrangement (NONE, RANGE, INDEFINITE)")
    sepal_range_min = serializers.IntegerField(help_text="Minimum number of sepals", allow_null=True)
    sepal_range_max = serializers.IntegerField(help_text="Maximum number of sepals", allow_null=True)
    sepals_fused = serializers.BooleanField(help_text="Whether sepals are fused (gamosepalous)")
    petal_arrangement = serializers.CharField(help_text="Type of petal arrangement (NONE, RANGE, INDEFINITE)")
    petal_range_min = serializers.IntegerField(help_text="Minimum number of petals", allow_null=True)
    petal_range_max = serializers.IntegerField(help_text="Maximum number of petals", allow_null=True)
    petals_fused = serializers.BooleanField(help_text="Whether petals are fused")
    stamens = serializers.CharField(help_text="Description of stamens")
    carpels = serializers.CharField(help_text="Description of carpels")
    
    class Meta:
        model = HermaphroditeFlower
        exclude = ('plant',)

class PlantListSerializer(serializers.ModelSerializer):
    """Simplified plant serializer for list views"""
    
    family_name = serializers.SerializerMethodField(help_text="Name of the plant's family in Arabic")
    name_arabic = serializers.CharField(help_text="Plant name in Arabic")
    name_english = serializers.CharField(help_text="Plant name in English", allow_blank=True)
    name_scientific = serializers.CharField(help_text="Scientific name of the plant")
    classification = serializers.CharField(help_text="Plant classification (e.g., 'بري', 'اقتصادي')")
    flower_type = serializers.CharField(help_text="Type of flower (BOTH or HERMAPHRODITE)")
    
    class Meta:
        model = Plant
        fields = ('id', 'name_arabic', 'name_english', 'name_scientific', 'family_name', 'classification', 'flower_type')
    
    def get_family_name(self, obj):
        return obj.family.name_arabic

class PlantDetailSerializer(serializers.ModelSerializer):
    """Detailed plant serializer including all nested flower information"""
    
    family = PlantFamilySerializer(read_only=True, help_text="Plant family information")
    male_flower = MaleFlowerSerializer(read_only=True, help_text="Male flower characteristics if flower_type is BOTH")
    female_flower = FemaleFlowerSerializer(read_only=True, help_text="Female flower characteristics if flower_type is BOTH")
    hermaphrodite_flower = HermaphroditeFlowerSerializer(read_only=True, help_text="Hermaphrodite flower characteristics if flower_type is HERMAPHRODITE")
    
    name_arabic = serializers.CharField(help_text="Plant name in Arabic")
    name_english = serializers.CharField(help_text="Plant name in English", allow_blank=True)
    name_scientific = serializers.CharField(help_text="Scientific name of the plant")
    classification = serializers.CharField(help_text="Plant classification (e.g., 'بري', 'اقتصادي')")
    seed_shape_arabic = serializers.CharField(help_text="Seed shape description in Arabic")
    seed_shape_english = serializers.CharField(help_text="Seed shape description in English", allow_blank=True)
    cotyledon_type = serializers.CharField(help_text="Type of cotyledon (MONO for monocotyledon, DI for dicotyledon)")
    flower_type = serializers.CharField(help_text="Type of flower (BOTH or HERMAPHRODITE)")
    
    class Meta:
        model = Plant
        fields = '__all__'