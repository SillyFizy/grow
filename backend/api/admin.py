# backend/api/admin.py
from django.contrib import admin
from django.utils.html import format_html, mark_safe
from django.utils import timezone
from django.contrib import messages
from django.db import connection, models, transaction
import traceback
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

    def response_change(self, request, obj):
        """Custom response after changing a submission"""
        if "_approve" in request.POST:
            # Call our approve method on just this submission
            queryset = PlantSubmission.objects.filter(pk=obj.pk)
            self.approve_submissions(request, queryset)
            return self.response_post_save_change(request, obj)

        return super().response_change(request, obj)

    def change_view(self, request, object_id, form_url='', extra_context=None):
        """Add an approve button to the change form"""
        extra_context = extra_context or {}
        submission = self.get_object(request, object_id)
        if submission and submission.status == 'pending':
            extra_context['show_approve_button'] = True
        return super().change_view(
            request, object_id, form_url, extra_context=extra_context
        )

    def render_change_form(self, request, context, add=False, change=False, form_url='', obj=None):
        """Add approve button to submission form"""
        if context.get('show_approve_button', False):
            context['submit_row'] = mark_safe(
                context.get('submit_row', '') +
                '<input type="submit" value="Approve & Create Plant" name="_approve" />'
            )
        return super().render_change_form(request, context, add, change, form_url, obj)

    def save_model(self, request, obj, form, change):
        """Override save method to handle status changes"""
        if change and 'status' in form.changed_data:
            # Get the original object from the database to check previous status
            try:
                original_obj = PlantSubmission.objects.get(pk=obj.pk)

                # If changing from pending to approved
                if original_obj.status == 'pending' and obj.status == 'approved':
                    try:
                        # Create plant using direct SQL
                        cursor = connection.cursor()

                        # Create SQL for insertion
                        sql = f"""
                        INSERT INTO api_plant (
                            name_arabic, name_english, name_scientific, 
                            family_id, classification, seed_shape_arabic, 
                            seed_shape_english, cotyledon_type, flower_type
                        ) VALUES (
                            '{obj.name_arabic.replace("'", "''")}', 
                            '{(obj.name_english or "").replace("'", "''")}', 
                            '{obj.name_scientific.replace("'", "''")}',
                            {obj.family_id}, 
                            '{obj.classification.replace("'", "''")}', 
                            '{obj.seed_shape_arabic.replace("'", "''")}',
                            '{(obj.seed_shape_english or "").replace("'", "''")}', 
                            '{obj.cotyledon_type}', 
                            '{obj.flower_type}'
                        ) RETURNING id;
                        """

                        cursor.execute(sql)
                        plant_id = cursor.fetchone()[0]

                        # Retrieve the plant to use in related objects
                        plant = Plant.objects.get(id=plant_id)

                        # Create flower records based on type
                        details = obj.additional_details or {}

                        if obj.flower_type == 'BOTH':
                            male_data = details.get('male_flower', {})
                            female_data = details.get('female_flower', {})

                            if male_data:
                                MaleFlower.objects.create(
                                    plant=plant,
                                    sepal_arrangement=male_data.get(
                                        'sepal_arrangement', 'RANGE'),
                                    sepal_range_min=male_data.get(
                                        'sepal_range_min'),
                                    sepal_range_max=male_data.get(
                                        'sepal_range_max'),
                                    sepals_fused=male_data.get(
                                        'sepals_fused', False),
                                    petal_arrangement=male_data.get(
                                        'petal_arrangement', 'RANGE'),
                                    petal_range_min=male_data.get(
                                        'petal_range_min'),
                                    petal_range_max=male_data.get(
                                        'petal_range_max'),
                                    petals_fused=male_data.get(
                                        'petals_fused', False),
                                    stamens=male_data.get(
                                        'stamens', 'Not specified')
                                )

                            if female_data:
                                FemaleFlower.objects.create(
                                    plant=plant,
                                    sepal_arrangement=female_data.get(
                                        'sepal_arrangement', 'RANGE'),
                                    sepal_range_min=female_data.get(
                                        'sepal_range_min'),
                                    sepal_range_max=female_data.get(
                                        'sepal_range_max'),
                                    sepals_fused=female_data.get(
                                        'sepals_fused', False),
                                    petal_arrangement=female_data.get(
                                        'petal_arrangement', 'RANGE'),
                                    petal_range_min=female_data.get(
                                        'petal_range_min'),
                                    petal_range_max=female_data.get(
                                        'petal_range_max'),
                                    petals_fused=female_data.get(
                                        'petals_fused', False),
                                    carpels=female_data.get(
                                        'carpels', 'Not specified')
                                )

                        elif obj.flower_type == 'HERMAPHRODITE':
                            herm_data = details.get('hermaphrodite_flower', {})

                            if herm_data:
                                HermaphroditeFlower.objects.create(
                                    plant=plant,
                                    sepal_arrangement=herm_data.get(
                                        'sepal_arrangement', 'RANGE'),
                                    sepal_range_min=herm_data.get(
                                        'sepal_range_min'),
                                    sepal_range_max=herm_data.get(
                                        'sepal_range_max'),
                                    sepals_fused=herm_data.get(
                                        'sepals_fused', False),
                                    petal_arrangement=herm_data.get(
                                        'petal_arrangement', 'RANGE'),
                                    petal_range_min=herm_data.get(
                                        'petal_range_min'),
                                    petal_range_max=herm_data.get(
                                        'petal_range_max'),
                                    petals_fused=herm_data.get(
                                        'petals_fused', False),
                                    stamens=herm_data.get(
                                        'stamens', 'Not specified'),
                                    carpels=herm_data.get(
                                        'carpels', 'Not specified')
                                )

                        # Add note about the plant creation
                        obj.admin_notes += f"\nApproved and created plant ID: {plant_id}"

                        # Show success message
                        messages.success(
                            request, f"Plant created successfully (ID: {plant_id})")

                    except Exception as e:
                        error_details = traceback.format_exc()
                        messages.error(
                            request, f"Error creating plant: {str(e)}")

            except PlantSubmission.DoesNotExist:
                # This would be a new object, not a status change
                pass

        # Save the submission
        super().save_model(request, obj, form, change)

    def approve_submissions(self, request, queryset):
        """Approve selected submissions and create plant records"""
        # Only process pending submissions
        pending_submissions = queryset.filter(status='pending')

        if not pending_submissions.exists():
            self.message_user(
                request,
                "No pending submissions selected. Only pending submissions can be approved.",
                level=messages.WARNING
            )
            return

        created_count = 0
        error_count = 0

        for submission in pending_submissions:
            try:
                # Use direct SQL insertion
                cursor = connection.cursor()

                # Create SQL for insertion
                sql = f"""
                INSERT INTO api_plant (
                    name_arabic, name_english, name_scientific, 
                    family_id, classification, seed_shape_arabic, 
                    seed_shape_english, cotyledon_type, flower_type
                ) VALUES (
                    '{submission.name_arabic.replace("'", "''")}', 
                    '{(submission.name_english or "").replace("'", "''")}', 
                    '{submission.name_scientific.replace("'", "''")}',
                    {submission.family_id}, 
                    '{submission.classification.replace("'", "''")}', 
                    '{submission.seed_shape_arabic.replace("'", "''")}',
                    '{(submission.seed_shape_english or "").replace("'", "''")}', 
                    '{submission.cotyledon_type}', 
                    '{submission.flower_type}'
                ) RETURNING id;
                """

                cursor.execute(sql)
                plant_id = cursor.fetchone()[0]

                # Retrieve the plant to use in related objects
                plant = Plant.objects.get(id=plant_id)

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
                        herm_flower = HermaphroditeFlower.objects.create(
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
                submission.admin_notes += f"\nApproved and created plant ID: {plant.id}"
                submission.save()

                created_count += 1

            except Exception as e:
                error_count += 1
                error_details = traceback.format_exc()

                self.message_user(
                    request,
                    f"Error approving submission {submission.id}: {str(e)}",
                    level=messages.ERROR
                )

        if created_count > 0:
            self.message_user(
                request,
                f"Successfully created {created_count} new plants from submissions.",
                level=messages.SUCCESS
            )
        elif error_count > 0:
            self.message_user(
                request,
                f"Failed to create plants. {error_count} errors encountered.",
                level=messages.ERROR
            )
        else:
            self.message_user(
                request,
                "No plants were created. Verify that you selected pending submissions.",
                level=messages.WARNING
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
