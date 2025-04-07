from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from .models import (
    PlantLocation, Profile, Category, Post,
    PlantFamily, Plant,
    MaleFlower, FemaleFlower, HermaphroditeFlower, PlantSubmission
)


class UserRegistrationSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'password2')

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError(
                {"password": "Password fields didn't match."})
        
        # Validate that email is unique
        email = attrs.get('email')
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError(
                {"email": "This email address is already in use."})
            
        return attrs

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )
        return user


class UserLoginSerializer(serializers.Serializer):
    login = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        # We'll handle the actual validation in the view
        return attrs

# Plant serializers


class PlantFamilySerializer(serializers.ModelSerializer):
    """Plant family serializer with complete details"""

    class Meta:
        model = PlantFamily
        fields = '__all__'


class MaleFlowerSerializer(serializers.ModelSerializer):
    """Serializer for male flower characteristics"""

    sepal_arrangement = serializers.CharField(
        help_text="Type of sepal arrangement (NONE, RANGE, INDEFINITE)")
    sepal_range_min = serializers.IntegerField(
        help_text="Minimum number of sepals", allow_null=True)
    sepal_range_max = serializers.IntegerField(
        help_text="Maximum number of sepals", allow_null=True)
    sepals_fused = serializers.BooleanField(
        help_text="Whether sepals are fused (gamosepalous)")
    petal_arrangement = serializers.CharField(
        help_text="Type of petal arrangement (NONE, RANGE, INDEFINITE)")
    petal_range_min = serializers.IntegerField(
        help_text="Minimum number of petals", allow_null=True)
    petal_range_max = serializers.IntegerField(
        help_text="Maximum number of petals", allow_null=True)
    petals_fused = serializers.BooleanField(
        help_text="Whether petals are fused")
    stamens = serializers.CharField(help_text="Description of stamens")

    class Meta:
        model = MaleFlower
        exclude = ('plant',)


class FemaleFlowerSerializer(serializers.ModelSerializer):
    """Serializer for female flower characteristics"""

    sepal_arrangement = serializers.CharField(
        help_text="Type of sepal arrangement (NONE, RANGE, INDEFINITE)")
    sepal_range_min = serializers.IntegerField(
        help_text="Minimum number of sepals", allow_null=True)
    sepal_range_max = serializers.IntegerField(
        help_text="Maximum number of sepals", allow_null=True)
    sepals_fused = serializers.BooleanField(
        help_text="Whether sepals are fused (gamosepalous)")
    petal_arrangement = serializers.CharField(
        help_text="Type of petal arrangement (NONE, RANGE, INDEFINITE)")
    petal_range_min = serializers.IntegerField(
        help_text="Minimum number of petals", allow_null=True)
    petal_range_max = serializers.IntegerField(
        help_text="Maximum number of petals", allow_null=True)
    petals_fused = serializers.BooleanField(
        help_text="Whether petals are fused")
    carpels = serializers.CharField(help_text="Description of carpels")

    class Meta:
        model = FemaleFlower
        exclude = ('plant',)


class HermaphroditeFlowerSerializer(serializers.ModelSerializer):
    """Serializer for hermaphrodite flower characteristics"""

    sepal_arrangement = serializers.CharField(
        help_text="Type of sepal arrangement (NONE, RANGE, INDEFINITE)")
    sepal_range_min = serializers.IntegerField(
        help_text="Minimum number of sepals", allow_null=True)
    sepal_range_max = serializers.IntegerField(
        help_text="Maximum number of sepals", allow_null=True)
    sepals_fused = serializers.BooleanField(
        help_text="Whether sepals are fused (gamosepalous)")
    petal_arrangement = serializers.CharField(
        help_text="Type of petal arrangement (NONE, RANGE, INDEFINITE)")
    petal_range_min = serializers.IntegerField(
        help_text="Minimum number of petals", allow_null=True)
    petal_range_max = serializers.IntegerField(
        help_text="Maximum number of petals", allow_null=True)
    petals_fused = serializers.BooleanField(
        help_text="Whether petals are fused")
    stamens = serializers.CharField(help_text="Description of stamens")
    carpels = serializers.CharField(help_text="Description of carpels")

    class Meta:
        model = HermaphroditeFlower
        exclude = ('plant',)


class PlantListSerializer(serializers.ModelSerializer):
    """Simplified plant serializer for list views"""

    family_name = serializers.SerializerMethodField(
        help_text="Name of the plant's family in Arabic")
    name_arabic = serializers.CharField(help_text="Plant name in Arabic")
    name_english = serializers.CharField(
        help_text="Plant name in English", allow_blank=True)
    name_scientific = serializers.CharField(
        help_text="Scientific name of the plant")
    classification = serializers.CharField(
        help_text="Plant classification (e.g., 'بري', 'اقتصادي')")
    flower_type = serializers.CharField(
        help_text="Type of flower (BOTH or HERMAPHRODITE)")
    image_url = serializers.SerializerMethodField(
        help_text="URL of the plant image if available")

    class Meta:
        model = Plant
        fields = ('id', 'name_arabic', 'name_english', 'name_scientific',
                  'family_name', 'classification', 'flower_type', 'image_url')

    def get_family_name(self, obj):
        return obj.family.name_arabic

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None


class PlantDetailSerializer(serializers.ModelSerializer):
    """Detailed plant serializer including all nested flower information"""

    family = PlantFamilySerializer(
        read_only=True, help_text="Plant family information")
    male_flower = MaleFlowerSerializer(
        read_only=True, help_text="Male flower characteristics if flower_type is BOTH")
    female_flower = FemaleFlowerSerializer(
        read_only=True, help_text="Female flower characteristics if flower_type is BOTH")
    hermaphrodite_flower = HermaphroditeFlowerSerializer(
        read_only=True, help_text="Hermaphrodite flower characteristics if flower_type is HERMAPHRODITE")
    image_url = serializers.SerializerMethodField(
        help_text="URL of the plant image if available")

    name_arabic = serializers.CharField(help_text="Plant name in Arabic")
    name_english = serializers.CharField(
        help_text="Plant name in English", allow_blank=True)
    name_scientific = serializers.CharField(
        help_text="Scientific name of the plant")
    classification = serializers.CharField(
        help_text="Plant classification (e.g., 'بري', 'اقتصادي')")
    description = serializers.CharField(
        help_text="Plant description", allow_blank=True)
    seed_shape_arabic = serializers.CharField(
        help_text="Seed shape description in Arabic")
    seed_shape_english = serializers.CharField(
        help_text="Seed shape description in English", allow_blank=True)
    cotyledon_type = serializers.CharField(
        help_text="Type of cotyledon (MONO for monocotyledon, DI for dicotyledon)")
    flower_type = serializers.CharField(
        help_text="Type of flower (BOTH or HERMAPHRODITE)")

    class Meta:
        model = Plant
        fields = '__all__'

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

# New serializers for plant submissions


class FlowerDetailsSerializer(serializers.Serializer):
    sepal_arrangement = serializers.ChoiceField(
        choices=['NONE', 'RANGE', 'INDEFINITE'])
    sepal_range_min = serializers.IntegerField(required=False, allow_null=True)
    sepal_range_max = serializers.IntegerField(required=False, allow_null=True)
    sepals_fused = serializers.BooleanField(default=False)

    petal_arrangement = serializers.ChoiceField(
        choices=['NONE', 'RANGE', 'INDEFINITE'])
    petal_range_min = serializers.IntegerField(required=False, allow_null=True)
    petal_range_max = serializers.IntegerField(required=False, allow_null=True)
    petals_fused = serializers.BooleanField(default=False)


class MaleFlowerSubmissionSerializer(FlowerDetailsSerializer):
    stamens = serializers.CharField(max_length=255)


class FemaleFlowerSubmissionSerializer(FlowerDetailsSerializer):
    carpels = serializers.CharField(max_length=255)


class HermaphroditeFlowerSubmissionSerializer(FlowerDetailsSerializer):
    stamens = serializers.CharField(max_length=255)
    carpels = serializers.CharField(max_length=255)


class PlantSubmissionSerializer(serializers.ModelSerializer):
    submitter = serializers.HiddenField(
        default=serializers.CurrentUserDefault())

    # Optional nested serializers for different flower types
    male_flower = MaleFlowerSubmissionSerializer(
        required=False, write_only=True)
    female_flower = FemaleFlowerSubmissionSerializer(
        required=False, write_only=True)
    hermaphrodite_flower = HermaphroditeFlowerSubmissionSerializer(
        required=False, write_only=True)

    # Field for image upload
    image = serializers.ImageField(
        required=False,
        write_only=True,
        help_text="Plant image to upload"
    )

    class Meta:
        model = PlantSubmission
        fields = [
            'id', 'name_arabic', 'name_english', 'name_scientific', 'family',
            'classification', 'description', 'seed_shape_arabic', 'seed_shape_english',
            'cotyledon_type', 'flower_type', 'submitter', 'submitted_at',
            'status', 'admin_notes', 'male_flower', 'female_flower',
            'hermaphrodite_flower', 'image'
        ]
        read_only_fields = ['id', 'submitter',
                            'submitted_at', 'status', 'admin_notes']

    def validate(self, data):
        # Validate that if image_captions is provided, it has the same length as images
        images = data.get('images', [])
        captions = data.get('image_captions', [])

        if captions and len(captions) != len(images):
            raise serializers.ValidationError({
                'image_captions': 'Number of captions must match number of images'
            })

        return data

    def create(self, validated_data):
        # Extract flower data
        male_flower_data = validated_data.pop('male_flower', None)
        female_flower_data = validated_data.pop('female_flower', None)
        hermaphrodite_flower_data = validated_data.pop(
            'hermaphrodite_flower', None)

        # Extract image data
        image = validated_data.pop('image', None)

        # Store flower details in additional_details field
        additional_details = {}
        if male_flower_data:
            additional_details['male_flower'] = male_flower_data
        if female_flower_data:
            additional_details['female_flower'] = female_flower_data
        if hermaphrodite_flower_data:
            additional_details['hermaphrodite_flower'] = hermaphrodite_flower_data

        # Store image info in additional_details
        if image:
            from django.core.files.storage import default_storage
            from django.core.files.base import ContentFile
            import os

            # Store image in a temporary folder
            filename = f"submission_{os.path.basename(image.name)}"
            path = default_storage.save(
                f"temp_submissions/{filename}", ContentFile(image.read()))

            # Store the path in the additional details
            additional_details['image_storage'] = path

        validated_data['additional_details'] = additional_details

        # Create the plant submission
        return super().create(validated_data)


class PlantLocationSerializer(serializers.ModelSerializer):
    """Serializer for plant location data"""
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    plant_name = serializers.SerializerMethodField(read_only=True)
    plant_image_url = serializers.SerializerMethodField(read_only=True)
    
    class Meta:
        model = PlantLocation
        fields = [
            'id', 'plant', 'plant_name', 'plant_image_url', 'user', 'latitude', 
            'longitude', 'quantity', 'notes', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_plant_name(self, obj):
        return obj.plant.name_arabic
    
    def get_plant_image_url(self, obj):
        if obj.plant.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.plant.image.url)
            return obj.plant.image.url
        return None