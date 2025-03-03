from django.core.management.base import BaseCommand
import csv
from api.models import PlantFamily, Plant, FlowerType, MaleFlower, FemaleFlower, HermaphroditeFlower

class Command(BaseCommand):
    help = 'Import plants data from CSV file'

    def add_arguments(self, parser):
        parser.add_argument('csv_file', type=str, help='Path to the CSV file')

    def handle(self, *args, **options):
        csv_file_path = options['csv_file']
        
        with open(csv_file_path, 'r', encoding='utf-8-sig') as file:
            csv_reader = csv.DictReader(file)
            
            for row in csv_reader:
                try:
                    # Create or get PlantFamily
                    family_name_arabic = row['العائلة'].strip()
                    family, created = PlantFamily.objects.get_or_create(
                        name_arabic=family_name_arabic,
                        defaults={
                            'name_english': '',  # You can add English names later
                            'name_scientific': '',
                        }
                    )

                    # Create Plant
                    plant = Plant.objects.create(
                        serial_number=int(float(row['ت'])),
                        name_arabic=row['اسم النبات'].strip(),
                        name_scientific=row['الاسم العلمي'].strip(),
                        family=family,
                        classification=row['التصنيف'].strip(),
                        seed_shape_arabic=row['شكل البذرة'].strip(),
                        cotyledon_type='MONO' if 'واحدة' in row['فلقة واحدة او اثنين'] else 'DI'
                    )

                    # Determine flower type
                    flower_type = 'BOTH'  # default
                    if row['الزهرة أحادية الجنس (خنثى)'].strip():
                        flower_type = 'HERMAPHRODITE'
                    elif row['الزهرة الذكرية'].strip() or row['الزهرة الانثوية'].strip():
                        flower_type = 'UNISEXUAL'

                    FlowerType.objects.create(
                        plant=plant,
                        type=flower_type
                    )

                    # Create Male Flower if exists
                    if row['الزهرة الذكرية'].strip():
                        MaleFlower.objects.create(
                            plant=plant,
                            sepals=row['Unnamed: 9'].strip() if row['Unnamed: 9'] else None,
                            petals=row['Unnamed: 10'].strip() if row['Unnamed: 10'] else None
                        )

                    # Create Female Flower if exists
                    if row['الزهرة الانثوية'].strip():
                        FemaleFlower.objects.create(
                            plant=plant,
                            sepals=row['Unnamed: 12'].strip() if row['Unnamed: 12'] else None,
                            petals=row['Unnamed: 13'].strip() if row['Unnamed: 13'] else None
                        )

                    # Create Hermaphrodite Flower if exists
                    if row['الزهرة أحادية الجنس (خنثى)'].strip():
                        HermaphroditeFlower.objects.create(
                            plant=plant,
                            sepals=row['Unnamed: 15'].strip() if row['Unnamed: 15'] else None,
                            petals=row['Unnamed: 16'].strip() if row['Unnamed: 16'] else None,
                            stamens=row['Unnamed: 17'].strip() if row['Unnamed: 17'] else None
                        )

                    self.stdout.write(
                        self.style.SUCCESS(f'Successfully imported plant: {plant.name_arabic}')
                    )

                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'Error importing row {row.get("ت", "unknown")}: {str(e)}')
                    )