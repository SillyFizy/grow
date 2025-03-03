from django.core.management.base import BaseCommand
import csv
import re
from api.models import Plant, MaleFlower, FemaleFlower, HermaphroditeFlower

class Command(BaseCommand):
    help = 'Import flower data from TSV file into the database'

    def add_arguments(self, parser):
        parser.add_argument('tsv_file', type=str, help='Path to the TSV file')
        parser.add_argument('--debug', action='store_true', help='Show detailed debugging information')

    def handle(self, *args, **options):
        tsv_file_path = options['tsv_file']
        debug = options['debug']
        
        if debug:
            self.stdout.write(self.style.SUCCESS('Running in debug mode'))
        
        # First, let's print out the column headers to help debug
        with open(tsv_file_path, 'r', encoding='utf-8') as file:
            first_line = file.readline().strip()
            if debug:
                self.stdout.write(self.style.WARNING(f'First line of the file: {first_line}'))
                self.stdout.write(self.style.WARNING(f'Fields detected: {first_line.split("\t")}'))
        
        # Now let's process the data
        with open(tsv_file_path, 'r', encoding='utf-8') as file:
            # Skip the header row to read it manually
            headers = file.readline().strip().split('\t')
            
            if debug:
                for i, header in enumerate(headers):
                    self.stdout.write(self.style.WARNING(f'Column {i}: {header}'))
            
            # Find important column indices
            col_indices = {}
            for i, header in enumerate(headers):
                # Store all column indices for easier reference
                col_indices[header] = i
            
            if debug:
                self.stdout.write(self.style.WARNING(f'Column indices: {col_indices}'))
            
            # Now read the rest of the file
            for line_num, line in enumerate(file, 2):  # Start at line 2
                if not line.strip():
                    continue
                
                fields = line.strip().split('\t')
                if len(fields) < len(headers):
                    if debug:
                        self.stdout.write(self.style.ERROR(f'Line {line_num} has fewer fields than headers: {len(fields)} vs {len(headers)}'))
                    # Pad with empty strings
                    fields.extend([''] * (len(headers) - len(fields)))
                
                try:
                    # Get basic data
                    plant_id = fields[col_indices['ID']] if 'ID' in col_indices else ''
                    arabic_name = fields[col_indices['Arabic Name / الاسم بالعربي']] if 'Arabic Name / الاسم بالعربي' in col_indices else ''
                    scientific_name = fields[col_indices['Scientific Name / الاسم العلمي']] if 'Scientific Name / الاسم العلمي' in col_indices else ''
                    flower_type = fields[col_indices['Flower Type / نوع الزهرة']] if 'Flower Type / نوع الزهرة' in col_indices else ''
                    
                    if debug:
                        self.stdout.write(self.style.SUCCESS(f'Processing: {plant_id}: {arabic_name} ({scientific_name})'))
                    
                    # Find the plant
                    plant = None
                    for search_field, search_value in [
                        ('id', plant_id),
                        ('name_scientific__startswith', scientific_name),
                        ('name_arabic', arabic_name)
                    ]:
                        if not search_value:
                            continue
                        
                        query_kwargs = {search_field: search_value}
                        if debug:
                            self.stdout.write(f'Searching with {query_kwargs}')
                        
                        try:
                            plants = Plant.objects.filter(**query_kwargs)
                            if plants.exists():
                                plant = plants.first()
                                if debug:
                                    self.stdout.write(self.style.SUCCESS(f'Found plant: {plant}'))
                                break
                        except Exception as e:
                            if debug:
                                self.stdout.write(self.style.ERROR(f'Search error: {str(e)}'))
                    
                    if not plant:
                        self.stdout.write(self.style.WARNING(f'Plant not found: ID={plant_id}, Name={scientific_name}'))
                        continue
                    
                    # Update flower type
                    if 'أحادية الجنس' in flower_type:
                        plant.flower_type = 'BOTH'
                    elif 'ثنائية الجنس' in flower_type or 'خنثى' in flower_type:
                        plant.flower_type = 'HERMAPHRODITE'
                    plant.save()
                    
                    if debug:
                        self.stdout.write(f'Plant flower type: {plant.flower_type}')
                    
                    # Define a helper function to parse flower part data
                    def parse_part_info(info):
                        arrangement = 'RANGE'  # Default
                        min_val = None
                        max_val = None
                        is_fused = False
                        
                        if not info or info == '' or 'لا يوجد' in info or 'None' in info:
                            arrangement = 'NONE'
                            return arrangement, min_val, max_val, is_fused
                            
                        if 'فيوز' in info or 'fused' in info or 'gamosepalous' in info or 'مندمجة' in info:
                            is_fused = True
                        
                        if 'غير محدد' in info or 'مالانهاية' in info or 'indefinite' in info:
                            arrangement = 'INDEFINITE'
                            min_match = re.search(r'(\d+)', info)
                            if min_match:
                                min_val = int(min_match.group(1))
                            return arrangement, min_val, max_val, is_fused
                        
                        range_patterns = [
                            r'(\d+)[ -]الى[ -](\d+)',  # Arabic style
                            r'(\d+)-(\d+)',           # Dash
                            r'(\d+)\s*to\s*(\d+)'     # English "to"
                        ]
                        
                        for pattern in range_patterns:
                            range_match = re.search(pattern, info)
                            if range_match:
                                min_val = int(range_match.group(1))
                                max_val = int(range_match.group(2))
                                return arrangement, min_val, max_val, is_fused
                        
                        # Single number
                        num_match = re.search(r'(\d+)', info)
                        if num_match:
                            min_val = max_val = int(num_match.group(1))
                        
                        return arrangement, min_val, max_val, is_fused
                    
                    # Process specific flower data based on type
                    if plant.flower_type == 'BOTH':
                        # Find all male flower related columns
                        male_sepal_info = ''
                        male_petal_info = ''
                        male_stamen_info = ''
                        
                        # Look for Male Flowers column
                        for col_name, idx in col_indices.items():
                            if 'Male Flowers' in col_name or 'الزهرة الذكرية' in col_name:
                                if idx < len(fields):
                                    male_sepal_info = fields[idx]
                                    
                                    # Try to find the next columns for petals and stamens
                                    if idx + 1 < len(fields):
                                        male_petal_info = fields[idx + 1]
                                    if idx + 2 < len(fields):
                                        male_stamen_info = fields[idx + 2]
                                break
                        
                        # Parse data
                        sepal_arr, sepal_min, sepal_max, sepals_fused = parse_part_info(male_sepal_info)
                        petal_arr, petal_min, petal_max, petals_fused = parse_part_info(male_petal_info)
                        
                        if debug:
                            self.stdout.write(f'MALE: Sepal: {sepal_arr}, {sepal_min}-{sepal_max}, fused: {sepals_fused}')
                            self.stdout.write(f'MALE: Petal: {petal_arr}, {petal_min}-{petal_max}, fused: {petals_fused}')
                            self.stdout.write(f'MALE: Stamen: {male_stamen_info}')
                        
                        # Create or update male flower
                        if male_sepal_info or male_petal_info or male_stamen_info:
                            try:
                                male_flower, created = MaleFlower.objects.update_or_create(
                                    plant=plant,
                                    defaults={
                                        'sepal_arrangement': sepal_arr,
                                        'sepal_range_min': sepal_min,
                                        'sepal_range_max': sepal_max,
                                        'sepals_fused': sepals_fused,
                                        'petal_arrangement': petal_arr,
                                        'petal_range_min': petal_min,
                                        'petal_range_max': petal_max,
                                        'petals_fused': petals_fused,
                                        'stamens': male_stamen_info
                                    }
                                )
                                if debug:
                                    if created:
                                        self.stdout.write(self.style.SUCCESS(f'Created male flower for {plant}'))
                                    else:
                                        self.stdout.write(self.style.SUCCESS(f'Updated male flower for {plant}'))
                            except Exception as e:
                                self.stdout.write(self.style.ERROR(f'Error creating male flower: {str(e)}'))
                        
                        # Find all female flower related columns
                        female_sepal_info = ''
                        female_petal_info = ''
                        female_carpel_info = ''
                        
                        # Look for Female Flowers column
                        for col_name, idx in col_indices.items():
                            if 'Female Flowers' in col_name or 'الزهرة الانثوية' in col_name:
                                if idx < len(fields):
                                    female_sepal_info = fields[idx]
                                    
                                    # Try to find the next columns for petals and carpels
                                    if idx + 1 < len(fields):
                                        female_petal_info = fields[idx + 1]
                                    if idx + 2 < len(fields):
                                        female_carpel_info = fields[idx + 2]
                                break
                        
                        # Parse data
                        sepal_arr, sepal_min, sepal_max, sepals_fused = parse_part_info(female_sepal_info)
                        petal_arr, petal_min, petal_max, petals_fused = parse_part_info(female_petal_info)
                        
                        if debug:
                            self.stdout.write(f'FEMALE: Sepal: {sepal_arr}, {sepal_min}-{sepal_max}, fused: {sepals_fused}')
                            self.stdout.write(f'FEMALE: Petal: {petal_arr}, {petal_min}-{petal_max}, fused: {petals_fused}')
                            self.stdout.write(f'FEMALE: Carpel: {female_carpel_info}')
                        
                        # Create or update female flower
                        if female_sepal_info or female_petal_info or female_carpel_info:
                            try:
                                female_flower, created = FemaleFlower.objects.update_or_create(
                                    plant=plant,
                                    defaults={
                                        'sepal_arrangement': sepal_arr,
                                        'sepal_range_min': sepal_min,
                                        'sepal_range_max': sepal_max,
                                        'sepals_fused': sepals_fused,
                                        'petal_arrangement': petal_arr,
                                        'petal_range_min': petal_min,
                                        'petal_range_max': petal_max,
                                        'petals_fused': petals_fused,
                                        'carpels': female_carpel_info
                                    }
                                )
                                if debug:
                                    if created:
                                        self.stdout.write(self.style.SUCCESS(f'Created female flower for {plant}'))
                                    else:
                                        self.stdout.write(self.style.SUCCESS(f'Updated female flower for {plant}'))
                            except Exception as e:
                                self.stdout.write(self.style.ERROR(f'Error creating female flower: {str(e)}'))
                    
                    elif plant.flower_type == 'HERMAPHRODITE':
                        # Find all hermaphrodite flower related columns
                        herm_sepal_info = ''
                        herm_petal_info = ''
                        herm_stamen_info = ''
                        herm_carpel_info = ''
                        
                        # Look for Hermaphrodite Flowers column
                        for col_name, idx in col_indices.items():
                            if 'الزهرة أحادية الجنس (خنثى)' in col_name or 'خنثى' in col_name:
                                if idx < len(fields):
                                    herm_sepal_info = fields[idx]
                                    
                                    # Try to find the next columns
                                    if idx + 1 < len(fields):
                                        herm_petal_info = fields[idx + 1]
                                    if idx + 2 < len(fields):
                                        herm_stamen_info = fields[idx + 2]
                                    if idx + 3 < len(fields):
                                        herm_carpel_info = fields[idx + 3]
                                break
                        
                        # Parse data
                        sepal_arr, sepal_min, sepal_max, sepals_fused = parse_part_info(herm_sepal_info)
                        petal_arr, petal_min, petal_max, petals_fused = parse_part_info(herm_petal_info)
                        
                        if debug:
                            self.stdout.write(f'HERM: Sepal: {sepal_arr}, {sepal_min}-{sepal_max}, fused: {sepals_fused}')
                            self.stdout.write(f'HERM: Petal: {petal_arr}, {petal_min}-{petal_max}, fused: {petals_fused}')
                            self.stdout.write(f'HERM: Stamen: {herm_stamen_info}')
                            self.stdout.write(f'HERM: Carpel: {herm_carpel_info}')
                        
                        # Create or update hermaphrodite flower
                        if herm_sepal_info or herm_petal_info or herm_stamen_info or herm_carpel_info:
                            try:
                                herm_flower, created = HermaphroditeFlower.objects.update_or_create(
                                    plant=plant,
                                    defaults={
                                        'sepal_arrangement': sepal_arr,
                                        'sepal_range_min': sepal_min,
                                        'sepal_range_max': sepal_max,
                                        'sepals_fused': sepals_fused,
                                        'petal_arrangement': petal_arr,
                                        'petal_range_min': petal_min,
                                        'petal_range_max': petal_max,
                                        'petals_fused': petals_fused,
                                        'stamens': herm_stamen_info,
                                        'carpels': herm_carpel_info
                                    }
                                )
                                if debug:
                                    if created:
                                        self.stdout.write(self.style.SUCCESS(f'Created hermaphrodite flower for {plant}'))
                                    else:
                                        self.stdout.write(self.style.SUCCESS(f'Updated hermaphrodite flower for {plant}'))
                            except Exception as e:
                                self.stdout.write(self.style.ERROR(f'Error creating hermaphrodite flower: {str(e)}'))
                    
                    self.stdout.write(self.style.SUCCESS(f'Successfully processed plant: {plant.name_arabic}'))
                
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'Error processing line {line_num}: {str(e)}'))
                    if debug:
                        import traceback
                        self.stdout.write(self.style.ERROR(traceback.format_exc()))