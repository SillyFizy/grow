from django import forms
from django.contrib import admin
from django.utils.html import format_html, mark_safe
from django.utils import timezone
from django.contrib import messages
from django.db import connection, models, transaction
import traceback
import os
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.conf import settings

from .models import (
    PlantLocation, Profile, Category, Post,
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
                    'family', 'classification', 'flower_type', 'image_preview')
    list_filter = ('family', 'cotyledon_type', 'flower_type')
    search_fields = ('name_arabic', 'name_english',
                     'name_scientific', 'description')
    ordering = ('id',)
    fieldsets = (
        ('Basic Information', {
            'fields': ('name_arabic', 'name_english', 'name_scientific', 'family',
                       'classification', 'description', 'image')
        }),
        ('Morphological Characteristics', {
            'fields': ('seed_shape_arabic', 'seed_shape_english', 'cotyledon_type', 'flower_type')
        }),
    )

    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" width="50" height="auto" />', obj.image.url)
        return "No Image"
    image_preview.short_description = 'Image'


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


class PlantSubmissionForm(forms.ModelForm):
    # Add an image upload field that's not part of the model
    image = forms.ImageField(required=False, label="Plant Image / صورة النبات")

    class Meta:
        model = PlantSubmission
        fields = '__all__'

    def save(self, commit=True):
        instance = super().save(commit=False)

        # Handle the image upload
        image = self.cleaned_data.get('image')
        if image:
            # Store image in a temporary folder
            filename = f"submission_{os.path.basename(image.name)}"
            path = default_storage.save(
                f"temp_submissions/{filename}", ContentFile(image.read()))

            # Add the image path to additional_details
            if not instance.additional_details:
                instance.additional_details = {}

            instance.additional_details['image_storage'] = path

        if commit:
            instance.save()

        return instance


@admin.register(PlantSubmission)
class PlantSubmissionAdmin(admin.ModelAdmin):
    form = PlantSubmissionForm  # Use our custom form
    list_display = ('name_arabic', 'name_scientific', 'family',
                    'submitter', 'submitted_at', 'status')
    list_filter = ('status', 'family', 'cotyledon_type', 'flower_type')
    search_fields = ('name_arabic', 'name_english',
                     'name_scientific', 'submitter__username', 'description')
    readonly_fields = (
        'submitted_at', 'additional_details_formatted', 'submission_image_preview')
    actions = ['approve_submissions', 'reject_submissions']

    fieldsets = (
        ('Basic Information', {
            'fields': ('name_arabic', 'name_english', 'name_scientific', 'family', 'classification', 'description')
        }),
        ('Morphological Characteristics', {
            'fields': ('seed_shape_arabic', 'seed_shape_english', 'cotyledon_type', 'flower_type')
        }),
        ('Image', {
            'fields': ('image', 'submission_image_preview')
        }),
        ('Submission Details', {
            'fields': ('submitter', 'submitted_at', 'status', 'admin_notes')
        }),
        ('Additional Information', {
            'fields': ('additional_details_formatted',)
        }),
    )

    def submission_image_preview(self, obj):
        """Display preview of uploaded image in the admin"""
        if not obj.additional_details or 'image_storage' not in obj.additional_details:
            return "No image uploaded"

        path = obj.additional_details['image_storage']
        if isinstance(path, str) and path:  # Check if path is a string and not empty
            from django.conf import settings
            return format_html('<img src="{}{}" style="max-width:300px; max-height:300px; object-fit:contain;" />',
                               settings.MEDIA_URL, path)
        elif isinstance(path, list):  # Handle the case where image_storage is a list of dicts
            from django.conf import settings
            html = ""
            for img_data in path:
                if isinstance(img_data, dict) and 'path' in img_data:
                    img_path = img_data.get('path')
                    html += format_html('<img src="{}{}" style="max-width:300px; max-height:300px; object-fit:contain; margin-right:10px;" />',
                                        settings.MEDIA_URL, img_path)
            return html if html else "No valid images"
        return "Image not available"
    submission_image_preview.short_description = "Uploaded Image"

    def temporary_images_preview(self, obj):
        """Display preview of uploaded images in the admin"""
        if not obj.additional_details or 'image_storage' not in obj.additional_details:
            return "No images uploaded"

        html = "<div style='display: flex; flex-wrap: wrap; gap: 10px;'>"
        for img_data in obj.additional_details['image_storage']:
            path = img_data.get('path')
            caption = img_data.get('caption', '')
            is_primary = img_data.get('is_primary', False)
            primary_label = "<span style='color:green; font-weight:bold;'>Primary</span>" if is_primary else ""

            if path:
                from django.conf import settings
                from django.templatetags.static import static

                html += f"""
                <div style='text-align:center; border:1px solid #ddd; padding:10px; border-radius:5px;'>
                    <img src="{settings.MEDIA_URL}{path}" style='max-width:200px; max-height:200px; object-fit:contain;' />
                    <div>{caption} {primary_label}</div>
                </div>
                """
        html += "</div>"
        return format_html(html)
    temporary_images_preview.short_description = "Uploaded Images"

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
        """Override save method to handle both image uploads and status changes"""
        # Handle image uploads directly from the form
        image = form.cleaned_data.get('image')
        if image:
            # Store image in a temporary folder
            filename = f"submission_{os.path.basename(image.name)}"
            path = default_storage.save(
                f"temp_submissions/{filename}", ContentFile(image.read()))

            # Add the image path to additional_details
            if not obj.additional_details:
                obj.additional_details = {}

            obj.additional_details['image_storage'] = path

        # Handle status changes (existing code)
        if change and 'status' in form.changed_data:
            # Get the original object from the database to check previous status
            try:
                original_obj = PlantSubmission.objects.get(pk=obj.pk)

                # If changing from pending to approved
                if original_obj.status == 'pending' and obj.status == 'approved':
                    try:
                        # Create plant using direct SQL
                        cursor = connection.cursor()

                        # Create SQL for insertion, now including description
                        sql = f"""
                        INSERT INTO api_plant (
                            name_arabic, name_english, name_scientific, 
                            family_id, classification, description, seed_shape_arabic, 
                            seed_shape_english, cotyledon_type, flower_type
                        ) VALUES (
                            '{obj.name_arabic.replace("'", "''")}', 
                            '{(obj.name_english or "").replace("'", "''")}', 
                            '{obj.name_scientific.replace("'", "''")}',
                            {obj.family_id}, 
                            '{obj.classification.replace("'", "''")}',
                            '{(obj.description or "").replace("'", "''")}',
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

                        # Process the image if available
                        details = obj.additional_details or {}
                        if 'image_storage' in details:
                            from django.core.files import File

                            path = details['image_storage']
                            if path:
                                try:
                                    # Get the full path to the file
                                    full_path = os.path.join(
                                        settings.MEDIA_ROOT, path)

                                    # Add the image to the plant
                                    with open(full_path, 'rb') as img_file:
                                        filename = os.path.basename(path)
                                        plant.image.save(
                                            filename, File(img_file), save=False)

                                    # Delete temporary file after saving the plant
                                    if os.path.exists(full_path):
                                        os.remove(full_path)
                                except Exception as e:
                                    # Log the error but continue
                                    obj.admin_notes += f"\nError processing image {path}: {str(e)}"

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
                # Create a new Plant instance directly
                plant = Plant(
                    name_arabic=submission.name_arabic,
                    name_english=submission.name_english,
                    name_scientific=submission.name_scientific,
                    family=submission.family,
                    classification=submission.classification,
                    description=submission.description,
                    seed_shape_arabic=submission.seed_shape_arabic,
                    seed_shape_english=submission.seed_shape_english,
                    cotyledon_type=submission.cotyledon_type,
                    flower_type=submission.flower_type
                )

                # Process the image if available
                details = submission.additional_details or {}
                if 'image_storage' in details:
                    from django.core.files import File
                    import os
                    from django.conf import settings

                    path = details['image_storage']
                    if path:
                        try:
                            # Get the full path to the file
                            full_path = os.path.join(settings.MEDIA_ROOT, path)

                            # Add the image to the plant
                            with open(full_path, 'rb') as img_file:
                                filename = os.path.basename(path)
                                plant.image.save(
                                    filename, File(img_file), save=False)

                            # Delete the temporary file after saving the plant
                            # (We'll delete it after saving the plant instance)
                        except Exception as e:
                            # Log the error but continue
                            submission.admin_notes += f"\nError processing image {path}: {str(e)}"

                # Save the plant
                plant.save()

                # Delete the temporary image file if it exists
                if 'image_storage' in details:
                    path = details['image_storage']
                    if path:
                        full_path = os.path.join(settings.MEDIA_ROOT, path)
                        if os.path.exists(full_path):
                            os.remove(full_path)

                # Create flower records based on type
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


@admin.register(PlantLocation)
class PlantLocationAdmin(admin.ModelAdmin):
    list_display = ('plant', 'user', 'latitude', 'longitude', 'quantity', 'created_at')
    list_filter = ('plant', 'user', 'created_at')
    search_fields = ('plant__name_arabic', 'plant__name_scientific', 'user__username', 'notes')
    readonly_fields = ('created_at',)
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Plant Information', {
            'fields': ('plant',)
        }),
        ('Location Details', {
            'fields': ('latitude', 'longitude', 'quantity', 'notes')
        }),
        ('Submission Info', {
            'fields': ('user', 'created_at')
        }),
    )
    
    def get_queryset(self, request):
        """Add annotation for the total plants found in each location record"""
        queryset = super().get_queryset(request)
        return queryset
