from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone
from django.contrib import messages
from django.db import models
from .models import (
    Profile, Category, Post,
    PlantFamily, Plant,
    MaleFlower, FemaleFlower, HermaphroditeFlower,
    PlantSubmission
)

# Unregister models if they're already registered to avoid duplicates
try:
    admin.site.unregister(Profile)
except admin.sites.NotRegistered:
    pass


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'location', 'birth_date',
                    'created_at', 'avatar_preview')
    list_filter = ('location', 'created_at')
    search_fields = ('user__username', 'location', 'bio')
    readonly_fields = ('created_at', 'updated_at')

    def avatar_preview(self, obj):
        if obj.avatar:
            return format_html('<img src="{}" width="50" height="50" style="border-radius: 50%;" />', obj.avatar.url)
        return "No Avatar"
    avatar_preview.short_description = 'Avatar'


@admin.register(PlantFamily)
class PlantFamilyAdmin(admin.ModelAdmin):
    list_display = ('name_arabic', 'name_english', 'name_scientific')
    search_fields = ('name_arabic', 'name_english', 'name_scientific')


@admin.register(Plant)
class PlantAdmin(admin.ModelAdmin):
    list_display = ('id', 'name_arabic', 'name_scientific',
                    'family', 'classification', 'flower_type')
    list_filter = ('family', 'cotyledon_type', 'flower_type')
    search_fields = ('name_arabic', 'name_english', 'name_scientific')
    ordering = ('id',)


class FlowerPartsAdmin(admin.ModelAdmin):
    """Base admin class for flower parts"""
    list_filter = ('sepal_arrangement', 'sepals_fused',
                   'petal_arrangement', 'petals_fused')
    search_fields = ('plant__name_arabic', 'plant__name_scientific')

    def get_sepal_info(self, obj):
        return obj.get_sepal_description()
    get_sepal_info.short_description = 'Sepals'

    def get_petal_info(self, obj):
        return obj.get_petal_description()
    get_petal_info.short_description = 'Petals'


@admin.register(MaleFlower)
class MaleFlowerAdmin(FlowerPartsAdmin):
    list_display = ('plant', 'get_sepal_info', 'get_petal_info', 'stamens')

    fieldsets = (
        ('Plant', {
            'fields': ('plant',)
        }),
        ('Sepals', {
            'fields': ('sepal_arrangement', 'sepal_range_min', 'sepal_range_max', 'sepals_fused')
        }),
        ('Petals', {
            'fields': ('petal_arrangement', 'petal_range_min', 'petal_range_max', 'petals_fused')
        }),
        ('Male Parts', {
            'fields': ('stamens',)
        }),
    )


@admin.register(FemaleFlower)
class FemaleFlowerAdmin(FlowerPartsAdmin):
    list_display = ('plant', 'get_sepal_info', 'get_petal_info', 'carpels')

    fieldsets = (
        ('Plant', {
            'fields': ('plant',)
        }),
        ('Sepals', {
            'fields': ('sepal_arrangement', 'sepal_range_min', 'sepal_range_max', 'sepals_fused')
        }),
        ('Petals', {
            'fields': ('petal_arrangement', 'petal_range_min', 'petal_range_max', 'petals_fused')
        }),
        ('Female Parts', {
            'fields': ('carpels',)
        }),
    )


@admin.register(HermaphroditeFlower)
class HermaphroditeFlowerAdmin(FlowerPartsAdmin):
    list_display = ('plant', 'get_sepal_info',
                    'get_petal_info', 'stamens', 'carpels')

    fieldsets = (
        ('Plant', {
            'fields': ('plant',)
        }),
        ('Sepals', {
            'fields': ('sepal_arrangement', 'sepal_range_min', 'sepal_range_max', 'sepals_fused')
        }),
        ('Petals', {
            'fields': ('petal_arrangement', 'petal_range_min', 'petal_range_max', 'petals_fused')
        }),
        ('Reproductive Parts', {
            'fields': ('stamens', 'carpels')
        }),
    )


@admin.register(PlantSubmission)
class PlantSubmissionAdmin(admin.ModelAdmin):
    list_display = ('name_arabic', 'name_scientific', 'family',
                    'submitter', 'submitted_at', 'status')
    list_filter = ('status', 'family', 'cotyledon_type', 'flower_type')
    search_fields = ('name_arabic', 'name_english',
                     'name_scientific', 'submitter__username')
    readonly_fields = ('submitted_at', 'additional_details_formatted')
    actions = ['approve_submissions', 'reject_submissions']

    def additional_details_formatted(self, obj):
        """Format the JSON data for display in admin"""
        if not obj.additional_details:
            return "No additional details"
        import json
        return format_html("<pre>{}</pre>", json.dumps(obj.additional_details, indent=4))
    additional_details_formatted.short_description = "Flower Details"

    def approve_submissions(self, request, queryset):
        """Approve selected submissions and create plant records"""
        created_count = 0
        error_count = 0

        for submission in queryset.filter(status='pending'):
            try:
                # Create new plant
                plant = Plant.objects.create(
                    name_arabic=submission.name_arabic,
                    name_english=submission.name_english,
                    name_scientific=submission.name_scientific,
                    family=submission.family,
                    classification=submission.classification,
                    seed_shape_arabic=submission.seed_shape_arabic,
                    seed_shape_english=submission.seed_shape_english,
                    cotyledon_type=submission.cotyledon_type,
                    flower_type=submission.flower_type
                )

                # Create flower records based on type
                details = submission.additional_details or {}

                if submission.flower_type == 'BOTH':
                    male_data = details.get('male_flower', {})
                    female_data = details.get('female_flower', {})

                    if male_data:
                        MaleFlower.objects.create(
                            plant=plant,
                            sepal_arrangement=male_data.get(
                                'sepal_arrangement', 'RANGE'),
                            sepal_range_min=male_data.get('sepal_range_min'),
                            sepal_range_max=male_data.get('sepal_range_max'),
                            sepals_fused=male_data.get('sepals_fused', False),
                            petal_arrangement=male_data.get(
                                'petal_arrangement', 'RANGE'),
                            petal_range_min=male_data.get('petal_range_min'),
                            petal_range_max=male_data.get('petal_range_max'),
                            petals_fused=male_data.get('petals_fused', False),
                            stamens=male_data.get('stamens', 'Not specified')
                        )

                    if female_data:
                        FemaleFlower.objects.create(
                            plant=plant,
                            sepal_arrangement=female_data.get(
                                'sepal_arrangement', 'RANGE'),
                            sepal_range_min=female_data.get('sepal_range_min'),
                            sepal_range_max=female_data.get('sepal_range_max'),
                            sepals_fused=female_data.get(
                                'sepals_fused', False),
                            petal_arrangement=female_data.get(
                                'petal_arrangement', 'RANGE'),
                            petal_range_min=female_data.get('petal_range_min'),
                            petal_range_max=female_data.get('petal_range_max'),
                            petals_fused=female_data.get(
                                'petals_fused', False),
                            carpels=female_data.get('carpels', 'Not specified')
                        )

                elif submission.flower_type == 'HERMAPHRODITE':
                    herm_data = details.get('hermaphrodite_flower', {})

                    if herm_data:
                        HermaphroditeFlower.objects.create(
                            plant=plant,
                            sepal_arrangement=herm_data.get(
                                'sepal_arrangement', 'RANGE'),
                            sepal_range_min=herm_data.get('sepal_range_min'),
                            sepal_range_max=herm_data.get('sepal_range_max'),
                            sepals_fused=herm_data.get('sepals_fused', False),
                            petal_arrangement=herm_data.get(
                                'petal_arrangement', 'RANGE'),
                            petal_range_min=herm_data.get('petal_range_min'),
                            petal_range_max=herm_data.get('petal_range_max'),
                            petals_fused=herm_data.get('petals_fused', False),
                            stamens=herm_data.get('stamens', 'Not specified'),
                            carpels=herm_data.get('carpels', 'Not specified')
                        )

                # Update submission status
                submission.status = 'approved'
                submission.admin_notes += f"\nApproved and created plant ID: {plant.id} on {timezone.now()}"
                submission.save()
                created_count += 1

            except Exception as e:
                error_count += 1
                self.message_user(
                    request,
                    f"Error approving submission {submission.id}: {str(e)}",
                    level=messages.ERROR
                )

        self.message_user(
            request,
            f"Processed {created_count} submissions successfully. {error_count} errors encountered."
        )
    approve_submissions.short_description = "Approve selected submissions and create plants"

    def reject_submissions(self, request, queryset):
        """Reject selected submissions"""
        count = queryset.filter(status='pending').update(
            status='rejected',
            admin_notes=models.F('admin_notes') +
            f"\nRejected on {timezone.now()}"
        )

        self.message_user(request, f"{count} submissions have been rejected")
    reject_submissions.short_description = "Reject selected submissions"


# Register JWT token models with admin
try:
    from rest_framework_simplejwt.token_blacklist.admin import OutstandingTokenAdmin
    from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken

    class CustomOutstandingTokenAdmin(OutstandingTokenAdmin):
        list_display = ('jti', 'user', 'created_at', 'expires_at')

    admin.site.unregister(OutstandingToken)
    admin.site.register(OutstandingToken, CustomOutstandingTokenAdmin)
except (ImportError, admin.sites.NotRegistered):
    pass
