from django.db import migrations

def update_flower_types(apps, schema_editor):
    Plant = apps.get_model('api', 'Plant')
    
    # IDs of plants that should have both male and female flowers
    both_type_ids = [1, 2, 4, 13, 14, 15, 17, 18, 19, 30, 33]
    
    # Update these plants to have flower_type = 'BOTH'
    Plant.objects.filter(id__in=both_type_ids).update(flower_type='BOTH')

def reverse_flower_types(apps, schema_editor):
    Plant = apps.get_model('api', 'Plant')
    # Revert all plants back to 'HERMAPHRODITE'
    Plant.objects.all().update(flower_type='HERMAPHRODITE')
    
class Migration(migrations.Migration):

    dependencies = [
        ('api', '0003_alter_plant_options_remove_plant_serial_number_and_more'),
    ]

    operations = [
    ]
