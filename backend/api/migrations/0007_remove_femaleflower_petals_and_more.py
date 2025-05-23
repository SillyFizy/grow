# Generated by Django 5.0.2 on 2025-02-24 11:13

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0006_remove_femaleflower_sepals_size_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='femaleflower',
            name='petals',
        ),
        migrations.RemoveField(
            model_name='hermaphroditeflower',
            name='petals',
        ),
        migrations.RemoveField(
            model_name='maleflower',
            name='petals',
        ),
        migrations.AddField(
            model_name='femaleflower',
            name='petal_arrangement',
            field=models.CharField(choices=[('NONE', 'None / لا يوجد'), ('RANGE', 'Range / نطاق محدد'), ('INDEFINITE', 'Indefinite / غير محدد')], default='RANGE', max_length=20, verbose_name='Petal Arrangement / نوع البتلات'),
        ),
        migrations.AddField(
            model_name='femaleflower',
            name='petal_range_max',
            field=models.PositiveSmallIntegerField(blank=True, null=True, verbose_name='Maximum Petals / الحد الأقصى للبتلات'),
        ),
        migrations.AddField(
            model_name='femaleflower',
            name='petal_range_min',
            field=models.PositiveSmallIntegerField(blank=True, null=True, verbose_name='Minimum Petals / الحد الأدنى للبتلات'),
        ),
        migrations.AddField(
            model_name='femaleflower',
            name='petals_fused',
            field=models.BooleanField(default=False, verbose_name='Fused Petals / بتلات ملتحمة'),
        ),
        migrations.AddField(
            model_name='hermaphroditeflower',
            name='petal_arrangement',
            field=models.CharField(choices=[('NONE', 'None / لا يوجد'), ('RANGE', 'Range / نطاق محدد'), ('INDEFINITE', 'Indefinite / غير محدد')], default='RANGE', max_length=20, verbose_name='Petal Arrangement / نوع البتلات'),
        ),
        migrations.AddField(
            model_name='hermaphroditeflower',
            name='petal_range_max',
            field=models.PositiveSmallIntegerField(blank=True, null=True, verbose_name='Maximum Petals / الحد الأقصى للبتلات'),
        ),
        migrations.AddField(
            model_name='hermaphroditeflower',
            name='petal_range_min',
            field=models.PositiveSmallIntegerField(blank=True, null=True, verbose_name='Minimum Petals / الحد الأدنى للبتلات'),
        ),
        migrations.AddField(
            model_name='hermaphroditeflower',
            name='petals_fused',
            field=models.BooleanField(default=False, verbose_name='Fused Petals / بتلات ملتحمة'),
        ),
        migrations.AddField(
            model_name='maleflower',
            name='petal_arrangement',
            field=models.CharField(choices=[('NONE', 'None / لا يوجد'), ('RANGE', 'Range / نطاق محدد'), ('INDEFINITE', 'Indefinite / غير محدد')], default='RANGE', max_length=20, verbose_name='Petal Arrangement / نوع البتلات'),
        ),
        migrations.AddField(
            model_name='maleflower',
            name='petal_range_max',
            field=models.PositiveSmallIntegerField(blank=True, null=True, verbose_name='Maximum Petals / الحد الأقصى للبتلات'),
        ),
        migrations.AddField(
            model_name='maleflower',
            name='petal_range_min',
            field=models.PositiveSmallIntegerField(blank=True, null=True, verbose_name='Minimum Petals / الحد الأدنى للبتلات'),
        ),
        migrations.AddField(
            model_name='maleflower',
            name='petals_fused',
            field=models.BooleanField(default=False, verbose_name='Fused Petals / بتلات ملتحمة'),
        ),
    ]
