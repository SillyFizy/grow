from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    bio = models.TextField(max_length=500, blank=True)
    location = models.CharField(max_length=100, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s profile"
    
class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = "Categories"

    def __str__(self):
        return self.name

class Post(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
        ('archived', 'Archived')
    ]

    title = models.CharField(max_length=200)
    content = models.TextField()
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='draft')
    featured_image = models.ImageField(upload_to='posts/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    views_count = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.title
    
class PlantFamily(models.Model):
    """Plant Family Classification"""
    name_arabic = models.CharField(max_length=100, verbose_name="Arabic Name")
    name_english = models.CharField(max_length=100, blank=True, verbose_name="English Name")
    name_scientific = models.CharField(max_length=100, blank=True, verbose_name="Scientific Name")
    description_arabic = models.TextField(blank=True, verbose_name="Arabic Description")
    description_english = models.TextField(blank=True, verbose_name="English Description")

    class Meta:
        verbose_name = "Plant Family"
        verbose_name_plural = "Plant Families"

    def __str__(self):
        return f"{self.name_arabic} / {self.name_english}"


class Plant(models.Model):
    """Main Plant Information"""
    COTYLEDON_CHOICES = [
        ('MONO', 'Monocotyledon / فلقة واحدة'),
        ('DI', 'Dicotyledon / فلقتين')
    ]

    FLOWER_TYPE_CHOICES = [
        ('BOTH', 'Both Male and Female / ذكرية وأنثوية'),
        ('HERMAPHRODITE', 'Hermaphrodite / خنثى')
    ]

    # Basic Information
    name_arabic = models.CharField(max_length=100, verbose_name="Arabic Name / الاسم بالعربي")
    name_english = models.CharField(max_length=100, blank=True, verbose_name="English Name / الاسم بالانجليزي")
    name_scientific = models.CharField(max_length=100, verbose_name="Scientific Name / الاسم العلمي")
    family = models.ForeignKey(PlantFamily, on_delete=models.PROTECT, verbose_name="Family / العائلة")
    classification = models.CharField(max_length=100, verbose_name="Classification / التصنيف")
    
    # Morphological Characteristics
    seed_shape_arabic = models.CharField(max_length=100, verbose_name="Seed Shape (Arabic) / شكل البذرة")
    seed_shape_english = models.CharField(max_length=100, blank=True, verbose_name="Seed Shape (English)")
    cotyledon_type = models.CharField(
        max_length=4, 
        choices=COTYLEDON_CHOICES, 
        verbose_name="Cotyledon Type / نوع الفلقة"
    )
    flower_type = models.CharField(
        max_length=20,
        choices=FLOWER_TYPE_CHOICES,
        verbose_name="Flower Type / نوع الزهرة"
    )

    class Meta:
        ordering = ['id']

    def __str__(self):
        return f"{self.name_arabic} ({self.name_scientific})"

class FlowerParts(models.Model):
    """Abstract base model for flower parts"""
    ARRANGEMENT_CHOICES = [
        ('NONE', 'None / لا يوجد'),
        ('RANGE', 'Range / نطاق محدد'),
        ('INDEFINITE', 'Indefinite / غير محدد')
    ]

    # Sepals fields
    sepal_arrangement = models.CharField(
        max_length=20,
        choices=ARRANGEMENT_CHOICES,
        default='RANGE',
        verbose_name="Sepal Arrangement / نوع السبلات"
    )
    sepal_range_min = models.PositiveSmallIntegerField(
        null=True, 
        blank=True,
        verbose_name="Minimum Sepals / الحد الأدنى للسبلات"
    )
    sepal_range_max = models.PositiveSmallIntegerField(
        null=True, 
        blank=True,
        verbose_name="Maximum Sepals / الحد الأقصى للسبلات"
    )
    sepals_fused = models.BooleanField(
        default=False,
        verbose_name="Fused Sepals (Gamosepalous) / سبلات ملتحمة"
    )
    
    # Petals fields
    petal_arrangement = models.CharField(
        max_length=20,
        choices=ARRANGEMENT_CHOICES,
        default='RANGE',
        verbose_name="Petal Arrangement / نوع البتلات"
    )
    petal_range_min = models.PositiveSmallIntegerField(
        null=True, 
        blank=True,
        verbose_name="Minimum Petals / الحد الأدنى للبتلات"
    )
    petal_range_max = models.PositiveSmallIntegerField(
        null=True, 
        blank=True,
        verbose_name="Maximum Petals / الحد الأقصى للبتلات"
    )
    petals_fused = models.BooleanField(
        default=False,
        verbose_name="Fused Petals / بتلات ملتحمة"
    )

    class Meta:
        abstract = True

    def get_sepal_description(self):
        """Returns a formatted description of the sepals"""
        if self.sepal_arrangement == 'NONE':
            return "None"
        elif self.sepal_arrangement == 'RANGE':
            if self.sepal_range_min == self.sepal_range_max:
                desc = f"{self.sepal_range_min}"
            else:
                desc = f"{self.sepal_range_min}-{self.sepal_range_max}"
        else:  # INDEFINITE
            desc = f"{self.sepal_range_min}+"

        if self.sepals_fused:
            desc += " (fused/gamosepalous)"
        return desc

    def get_petal_description(self):
        """Returns a formatted description of the petals"""
        if self.petal_arrangement == 'NONE':
            return "None"
        elif self.petal_arrangement == 'RANGE':
            if self.petal_range_min == self.petal_range_max:
                desc = f"{self.petal_range_min}"
            else:
                desc = f"{self.petal_range_min}-{self.petal_range_max}"
        else:  # INDEFINITE
            desc = f"{self.petal_range_min}+"

        if self.petals_fused:
            desc += " (fused)"
        return desc
    
class MaleFlower(FlowerParts):
    """Male flower characteristics"""
    plant = models.OneToOneField(
        Plant, 
        on_delete=models.CASCADE, 
        related_name='male_flower',
        limit_choices_to={'flower_type': 'BOTH'}
    )
    
    stamens = models.CharField(
        max_length=255, 
        verbose_name="Stamens / الاسدية"
    )

    class Meta:
        verbose_name = "Male Flower"
        verbose_name_plural = "Male Flowers"

    def __str__(self):
        return f"Male flower of {self.plant.name_arabic}"

class FemaleFlower(FlowerParts):
    """Female flower characteristics"""
    plant = models.OneToOneField(
        Plant, 
        on_delete=models.CASCADE, 
        related_name='female_flower',
        limit_choices_to={'flower_type': 'BOTH'}
    )
    
    carpels = models.CharField(
        max_length=255,
        verbose_name="Carpels / الكرابل"
    )

    class Meta:
        verbose_name = "Female Flower"
        verbose_name_plural = "Female Flowers"

    def __str__(self):
        return f"Female flower of {self.plant.name_arabic}"

class HermaphroditeFlower(FlowerParts):
    """Hermaphrodite flower characteristics"""
    plant = models.OneToOneField(
        Plant, 
        on_delete=models.CASCADE, 
        related_name='hermaphrodite_flower',
        limit_choices_to={'flower_type': 'HERMAPHRODITE'}
    )
    
    stamens = models.CharField(
        max_length=255, 
        verbose_name="Stamens / الاسدية",
        default="Not specified"  # Adding default value
    )
    
    carpels = models.CharField(
        max_length=255,
        verbose_name="Carpels / الكرابل"
    )

    class Meta:
        verbose_name = "Hermaphrodite Flower"
        verbose_name_plural = "Hermaphrodite Flowers"

    def __str__(self):
        return f"Hermaphrodite flower of {self.plant.name_arabic}"