from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Profile, Category, Post, 
    PlantFamily, Plant,
    MaleFlower, FemaleFlower, HermaphroditeFlower
)

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'location', 'birth_date', 'created_at', 'avatar_preview')
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
    list_display = ('id', 'name_arabic', 'name_scientific', 'family', 'classification', 'flower_type')
    list_filter = ('family', 'cotyledon_type', 'flower_type')
    search_fields = ('name_arabic', 'name_english', 'name_scientific')
    ordering = ('id',)

class FlowerPartsAdmin(admin.ModelAdmin):
    """Base admin class for flower parts"""
    list_filter = ('sepal_arrangement', 'sepals_fused', 'petal_arrangement', 'petals_fused')
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
    list_display = ('plant', 'get_sepal_info', 'get_petal_info', 'stamens', 'carpels')
    
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