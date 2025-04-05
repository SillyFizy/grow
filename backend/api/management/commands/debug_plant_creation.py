from django.core.management.base import BaseCommand
from api.models import PlantSubmission, Plant, MaleFlower, FemaleFlower, HermaphroditeFlower
import traceback
import sys

class Command(BaseCommand):
    help = 'Debug plant creation from a submission'

    def add_arguments(self, parser):
        parser.add_argument('submission_id', type=int, help='ID of the submission to convert to a plant')

    def handle(self, *args, **options):
        submission_id = options['submission_id']
        
        try:
            # First, get some diagnostics
            self.stdout.write(self.style.SUCCESS(f"Current Plant count: {Plant.objects.count()}"))
            
            # Get the submission
            try:
                submission = PlantSubmission.objects.get(id=submission_id)
                self.stdout.write(self.style.SUCCESS(f"Found submission: {submission.name_arabic}"))
            except PlantSubmission.DoesNotExist:
                self.stdout.write(self.style.ERROR(f"Submission with ID {submission_id} not found"))
                return
            
            # Print submission details
            self.stdout.write(self.style.SUCCESS("Submission details:"))
            for field in submission._meta.fields:
                self.stdout.write(f"  {field.name}: {getattr(submission, field.name)}")
            
            # Try creating the plant
            self.stdout.write(self.style.SUCCESS("\nCreating plant..."))
            try:
                # Use direct SQL to bypass Django's ORM
                from django.db import connection
                cursor = connection.cursor()
                
                # Create SQL for debugging
                sql = f"""
                INSERT INTO api_plant (
                    name_arabic, name_english, name_scientific, 
                    family_id, classification, seed_shape_arabic, 
                    seed_shape_english, cotyledon_type, flower_type
                ) VALUES (
                    '{submission.name_arabic}', '{submission.name_english or ""}', '{submission.name_scientific}',
                    {submission.family_id}, '{submission.classification}', '{submission.seed_shape_arabic}',
                    '{submission.seed_shape_english or ""}', '{submission.cotyledon_type}', '{submission.flower_type}'
                ) RETURNING id;
                """
                
                self.stdout.write(f"Executing SQL:\n{sql}")
                cursor.execute(sql)
                plant_id = cursor.fetchone()[0]
                self.stdout.write(self.style.SUCCESS(f"Plant created with ID: {plant_id}"))
                
                # Now try to retrieve the plant to confirm it was created
                plant = Plant.objects.get(id=plant_id)
                self.stdout.write(self.style.SUCCESS(f"Retrieved plant: {plant.name_arabic}"))
                
                # Create flower records based on type
                details = submission.additional_details or {}
                
                if submission.flower_type == 'BOTH':
                    male_data = details.get('male_flower', {})
                    female_data = details.get('female_flower', {})
                    
                    if male_data:
                        self.stdout.write("Creating male flower...")
                        male_flower = MaleFlower.objects.create(
                            plant=plant,
                            sepal_arrangement=male_data.get('sepal_arrangement', 'RANGE'),
                            sepal_range_min=male_data.get('sepal_range_min'),
                            sepal_range_max=male_data.get('sepal_range_max'),
                            sepals_fused=male_data.get('sepals_fused', False),
                            petal_arrangement=male_data.get('petal_arrangement', 'RANGE'),
                            petal_range_min=male_data.get('petal_range_min'),
                            petal_range_max=male_data.get('petal_range_max'),
                            petals_fused=male_data.get('petals_fused', False),
                            stamens=male_data.get('stamens', 'Not specified')
                        )
                        self.stdout.write(self.style.SUCCESS(f"Male flower created with ID: {male_flower.id}"))
                    
                    if female_data:
                        self.stdout.write("Creating female flower...")
                        female_flower = FemaleFlower.objects.create(
                            plant=plant,
                            sepal_arrangement=female_data.get('sepal_arrangement', 'RANGE'),
                            sepal_range_min=female_data.get('sepal_range_min'),
                            sepal_range_max=female_data.get('sepal_range_max'),
                            sepals_fused=female_data.get('sepals_fused', False),
                            petal_arrangement=female_data.get('petal_arrangement', 'RANGE'),
                            petal_range_min=female_data.get('petal_range_min'),
                            petal_range_max=female_data.get('petal_range_max'),
                            petals_fused=female_data.get('petals_fused', False),
                            carpels=female_data.get('carpels', 'Not specified')
                        )
                        self.stdout.write(self.style.SUCCESS(f"Female flower created with ID: {female_flower.id}"))
                
                elif submission.flower_type == 'HERMAPHRODITE':
                    herm_data = details.get('hermaphrodite_flower', {})
                    
                    if herm_data:
                        self.stdout.write("Creating hermaphrodite flower...")
                        herm_flower = HermaphroditeFlower.objects.create(
                            plant=plant,
                            sepal_arrangement=herm_data.get('sepal_arrangement', 'RANGE'),
                            sepal_range_min=herm_data.get('sepal_range_min'),
                            sepal_range_max=herm_data.get('sepal_range_max'),
                            sepals_fused=herm_data.get('sepals_fused', False),
                            petal_arrangement=herm_data.get('petal_arrangement', 'RANGE'),
                            petal_range_min=herm_data.get('petal_range_min'),
                            petal_range_max=herm_data.get('petal_range_max'),
                            petals_fused=herm_data.get('petals_fused', False),
                            stamens=herm_data.get('stamens', 'Not specified'),
                            carpels=herm_data.get('carpels', 'Not specified')
                        )
                        self.stdout.write(self.style.SUCCESS(f"Hermaphrodite flower created with ID: {herm_flower.id}"))
                
                # Update submission status
                submission.status = 'approved'
                submission.admin_notes += f"\nApproved and created plant ID: {plant.id} using debug command"
                submission.save()
                self.stdout.write(self.style.SUCCESS(f"Updated submission status to 'approved'"))
                
                # Final check
                self.stdout.write(self.style.SUCCESS(f"Final Plant count: {Plant.objects.count()}"))
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error creating plant: {str(e)}"))
                self.stdout.write(self.style.ERROR(traceback.format_exc()))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"General error: {str(e)}"))
            self.stdout.write(self.style.ERROR(traceback.format_exc()))