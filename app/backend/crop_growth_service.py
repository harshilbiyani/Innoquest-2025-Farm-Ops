"""
Crop Growth Timeline and Water Consumption Service
Generates dynamic timelines and water requirements based on crop type and soil conditions
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple


class CropGrowthService:
    """Service for generating crop growth timelines and water consumption data"""

    # Soil type characteristics and adjustments
    SOIL_TYPES = {
        'clayey_moist': {
            'name': 'Clay Soil (Moist)',
            'description': 'Dense soil that retains water well but can be difficult to work with.',
            'water_retention': 'high',
            'drainage': 'poor',
            'fertility': 'medium',
        },
        'clayey_dry': {
            'name': 'Clay Soil (Dry)',
            'description': 'Dense soil that becomes hard when dry, requiring careful water management.',
            'water_retention': 'high',
            'drainage': 'poor',
            'fertility': 'medium',
        },
        'sandy_moist': {
            'name': 'Sandy Soil (Moist)',
            'description': 'Light soil with excellent drainage but requires frequent watering.',
            'water_retention': 'low',
            'drainage': 'excellent',
            'fertility': 'low',
        },
        'sandy_dry': {
            'name': 'Sandy Soil (Dry)',
            'description': 'Very light soil that drains quickly and needs regular irrigation.',
            'water_retention': 'very_low',
            'drainage': 'excellent',
            'fertility': 'low',
        },
        'loamy_moist': {
            'name': 'Loamy Soil (Moist)',
            'description': 'Ideal balanced soil with good drainage and water retention.',
            'water_retention': 'medium',
            'drainage': 'good',
            'fertility': 'high',
        },
        'loamy_dry': {
            'name': 'Loamy Soil (Dry)',
            'description': 'Good balanced soil that needs regular watering during dry periods.',
            'water_retention': 'medium',
            'drainage': 'good',
            'fertility': 'high',
        },
        'black_cotton': {
            'name': 'Black Cotton Soil',
            'description': 'Highly fertile soil rich in clay, excellent for cotton and other crops.',
            'water_retention': 'high',
            'drainage': 'moderate',
            'fertility': 'very_high',
        },
        'red_soil': {
            'name': 'Red Soil',
            'description': 'Common laterite soil with good drainage, needs fertilizer enrichment.',
            'water_retention': 'medium',
            'drainage': 'good',
            'fertility': 'medium',
        },
        'alluvial': {
            'name': 'Alluvial Soil',
            'description': 'Rich river deposited soil, highly fertile and productive.',
            'water_retention': 'medium',
            'drainage': 'good',
            'fertility': 'very_high',
        },
        'laterite': {
            'name': 'Laterite Soil',
            'description': 'Iron-rich red soil, suitable for specific crops with proper management.',
            'water_retention': 'low',
            'drainage': 'good',
            'fertility': 'low',
        },
    }

    # Crop growth timeline templates (in days)
    CROP_TIMELINES = {
        'sugarcane': {
            'total_days': 365,
            'phases': [
                {'name': 'Land Preparation', 'duration': 15, 'category': 'Treatment', 'offset': 0},
                {'name': 'Planting', 'duration': 10, 'category': 'Critical', 'offset': 15},
                {'name': 'Germination', 'duration': 30, 'category': 'Critical', 'offset': 25},
                {'name': 'Tillering', 'duration': 60, 'category': 'High', 'offset': 55},
                {'name': 'Grand Growth', 'duration': 90, 'category': 'High', 'offset': 115},
                {'name': 'Maturation', 'duration': 90, 'category': 'Normal', 'offset': 205},
                {'name': 'Ripening', 'duration': 60, 'category': 'Normal', 'offset': 295},
                {'name': 'Harvesting', 'duration': 10, 'category': 'Critical', 'offset': 355},
            ],
            'water_total': '2000-2500 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '300-400 mm', 'intensity': 'high'},
                {'stage': 'Tillering', 'amount': '400-500 mm', 'intensity': 'high'},
                {'stage': 'Grand Growth', 'amount': '700-900 mm', 'intensity': 'high'},
                {'stage': 'Maturation', 'amount': '400-500 mm', 'intensity': 'medium'},
                {'stage': 'Ripening', 'amount': '200-300 mm', 'intensity': 'low'},
            ],
        },
        'cotton': {
            'total_days': 180,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Sowing', 'duration': 7, 'category': 'Critical', 'offset': 10},
                {'name': 'Germination', 'duration': 15, 'category': 'Critical', 'offset': 17},
                {'name': 'Vegetative Growth', 'duration': 50, 'category': 'High', 'offset': 32},
                {'name': 'Flowering', 'duration': 45, 'category': 'Critical', 'offset': 82},
                {'name': 'Boll Development', 'duration': 40, 'category': 'High', 'offset': 127},
                {'name': 'Boll Opening', 'duration': 18, 'category': 'Normal', 'offset': 167},
                {'name': 'Harvesting', 'duration': 15, 'category': 'Critical', 'offset': 185},
            ],
            'water_total': '700-1300 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '200-300 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '250-400 mm', 'intensity': 'high'},
                {'stage': 'Boll Development', 'amount': '150-300 mm', 'intensity': 'medium'},
                {'stage': 'Boll Opening', 'amount': '50-100 mm', 'intensity': 'low'},
            ],
        },
        'soyabean': {
            'total_days': 120,
            'phases': [
                {'name': 'Land Preparation', 'duration': 7, 'category': 'Treatment', 'offset': 0},
                {'name': 'Sowing', 'duration': 5, 'category': 'Critical', 'offset': 7},
                {'name': 'Germination', 'duration': 10, 'category': 'Critical', 'offset': 12},
                {'name': 'Vegetative Growth', 'duration': 35, 'category': 'High', 'offset': 22},
                {'name': 'Flowering', 'duration': 20, 'category': 'Critical', 'offset': 57},
                {'name': 'Pod Formation', 'duration': 25, 'category': 'High', 'offset': 77},
                {'name': 'Pod Filling', 'duration': 18, 'category': 'Normal', 'offset': 102},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 120},
            ],
            'water_total': '450-700 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '50-80 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '150-200 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Pod Formation', 'amount': '100-150 mm', 'intensity': 'medium'},
                {'stage': 'Pod Filling', 'amount': '50-120 mm', 'intensity': 'medium'},
            ],
        },
        'rice': {
            'total_days': 140,
            'phases': [
                {'name': 'Land Preparation & Puddling', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Transplanting', 'duration': 7, 'category': 'Critical', 'offset': 10},
                {'name': 'Tillering', 'duration': 30, 'category': 'Critical', 'offset': 17},
                {'name': 'Stem Elongation', 'duration': 20, 'category': 'High', 'offset': 47},
                {'name': 'Panicle Initiation', 'duration': 15, 'category': 'Critical', 'offset': 67},
                {'name': 'Flowering', 'duration': 15, 'category': 'Critical', 'offset': 82},
                {'name': 'Grain Filling', 'duration': 30, 'category': 'High', 'offset': 97},
                {'name': 'Ripening', 'duration': 13, 'category': 'Normal', 'offset': 127},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 140},
            ],
            'water_total': '1200-1500 mm',
            'water_stages': [
                {'stage': 'Land Preparation', 'amount': '200-250 mm', 'intensity': 'high'},
                {'stage': 'Tillering', 'amount': '300-400 mm', 'intensity': 'high'},
                {'stage': 'Panicle Initiation', 'amount': '200-250 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '250-300 mm', 'intensity': 'high'},
                {'stage': 'Grain Filling', 'amount': '200-250 mm', 'intensity': 'medium'},
                {'stage': 'Ripening', 'amount': '50-100 mm', 'intensity': 'low'},
            ],
        },
        'jowar': {
            'total_days': 120,
            'phases': [
                {'name': 'Land Preparation', 'duration': 7, 'category': 'Treatment', 'offset': 0},
                {'name': 'Sowing', 'duration': 5, 'category': 'Critical', 'offset': 7},
                {'name': 'Germination', 'duration': 10, 'category': 'Critical', 'offset': 12},
                {'name': 'Vegetative Growth', 'duration': 40, 'category': 'High', 'offset': 22},
                {'name': 'Flowering', 'duration': 20, 'category': 'Critical', 'offset': 62},
                {'name': 'Grain Filling', 'duration': 28, 'category': 'High', 'offset': 82},
                {'name': 'Maturity', 'duration': 10, 'category': 'Normal', 'offset': 110},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 120},
            ],
            'water_total': '400-600 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '50-80 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '150-200 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Grain Filling', 'amount': '80-120 mm', 'intensity': 'medium'},
                {'stage': 'Maturity', 'amount': '20-50 mm', 'intensity': 'low'},
            ],
        },
        'tur': {
            'total_days': 180,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Sowing', 'duration': 7, 'category': 'Critical', 'offset': 10},
                {'name': 'Germination', 'duration': 12, 'category': 'Critical', 'offset': 17},
                {'name': 'Vegetative Growth', 'duration': 50, 'category': 'High', 'offset': 29},
                {'name': 'Flowering', 'duration': 30, 'category': 'Critical', 'offset': 79},
                {'name': 'Pod Formation', 'duration': 35, 'category': 'High', 'offset': 109},
                {'name': 'Pod Filling', 'duration': 28, 'category': 'Normal', 'offset': 144},
                {'name': 'Harvesting', 'duration': 8, 'category': 'Critical', 'offset': 172},
            ],
            'water_total': '500-800 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '60-100 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '150-250 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '150-200 mm', 'intensity': 'high'},
                {'stage': 'Pod Formation', 'amount': '100-150 mm', 'intensity': 'medium'},
                {'stage': 'Pod Filling', 'amount': '40-100 mm', 'intensity': 'low'},
            ],
        },
        'wheat': {
            'total_days': 140,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Sowing', 'duration': 7, 'category': 'Critical', 'offset': 10},
                {'name': 'Germination', 'duration': 12, 'category': 'Critical', 'offset': 17},
                {'name': 'Tillering', 'duration': 30, 'category': 'High', 'offset': 29},
                {'name': 'Jointing', 'duration': 20, 'category': 'High', 'offset': 59},
                {'name': 'Flowering', 'duration': 15, 'category': 'Critical', 'offset': 79},
                {'name': 'Grain Filling', 'duration': 30, 'category': 'High', 'offset': 94},
                {'name': 'Ripening', 'duration': 14, 'category': 'Normal', 'offset': 124},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 138},
            ],
            'water_total': '450-650 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '60-80 mm', 'intensity': 'high'},
                {'stage': 'Tillering', 'amount': '120-150 mm', 'intensity': 'high'},
                {'stage': 'Jointing', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '80-120 mm', 'intensity': 'high'},
                {'stage': 'Grain Filling', 'amount': '70-100 mm', 'intensity': 'medium'},
                {'stage': 'Ripening', 'amount': '20-50 mm', 'intensity': 'low'},
            ],
        },
        'groundnut': {
            'total_days': 120,
            'phases': [
                {'name': 'Land Preparation', 'duration': 7, 'category': 'Treatment', 'offset': 0},
                {'name': 'Sowing', 'duration': 5, 'category': 'Critical', 'offset': 7},
                {'name': 'Germination', 'duration': 10, 'category': 'Critical', 'offset': 12},
                {'name': 'Vegetative Growth', 'duration': 35, 'category': 'High', 'offset': 22},
                {'name': 'Flowering & Pegging', 'duration': 25, 'category': 'Critical', 'offset': 57},
                {'name': 'Pod Development', 'duration': 30, 'category': 'High', 'offset': 82},
                {'name': 'Maturation', 'duration': 13, 'category': 'Normal', 'offset': 112},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 125},
            ],
            'water_total': '500-700 mm',
            'water_stages': [
                {'stage': 'Germination', 'amount': '50-80 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '150-200 mm', 'intensity': 'high'},
                {'stage': 'Flowering & Pegging', 'amount': '150-200 mm', 'intensity': 'high'},
                {'stage': 'Pod Development', 'amount': '120-170 mm', 'intensity': 'medium'},
                {'stage': 'Maturation', 'amount': '30-50 mm', 'intensity': 'low'},
            ],
        },
        'onion': {
            'total_days': 140,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Nursery/Transplanting', 'duration': 15, 'category': 'Critical', 'offset': 10},
                {'name': 'Establishment', 'duration': 20, 'category': 'Critical', 'offset': 25},
                {'name': 'Vegetative Growth', 'duration': 40, 'category': 'High', 'offset': 45},
                {'name': 'Bulb Formation', 'duration': 35, 'category': 'Critical', 'offset': 85},
                {'name': 'Bulb Enlargement', 'duration': 20, 'category': 'High', 'offset': 120},
                {'name': 'Maturation', 'duration': 10, 'category': 'Normal', 'offset': 140},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 150},
            ],
            'water_total': '350-550 mm',
            'water_stages': [
                {'stage': 'Establishment', 'amount': '60-100 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '120-150 mm', 'intensity': 'high'},
                {'stage': 'Bulb Formation', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Bulb Enlargement', 'amount': '60-100 mm', 'intensity': 'medium'},
                {'stage': 'Maturation', 'amount': '10-50 mm', 'intensity': 'low'},
            ],
        },
        'tomato': {
            'total_days': 120,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Nursery/Transplanting', 'duration': 15, 'category': 'Critical', 'offset': 10},
                {'name': 'Establishment', 'duration': 15, 'category': 'Critical', 'offset': 25},
                {'name': 'Vegetative Growth', 'duration': 25, 'category': 'High', 'offset': 40},
                {'name': 'Flowering', 'duration': 20, 'category': 'Critical', 'offset': 65},
                {'name': 'Fruit Setting', 'duration': 15, 'category': 'High', 'offset': 85},
                {'name': 'Fruit Development', 'duration': 25, 'category': 'High', 'offset': 100},
                {'name': 'Harvesting', 'duration': 20, 'category': 'Normal', 'offset': 125},
            ],
            'water_total': '400-600 mm',
            'water_stages': [
                {'stage': 'Establishment', 'amount': '60-80 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Flowering', 'amount': '80-120 mm', 'intensity': 'high'},
                {'stage': 'Fruit Setting', 'amount': '70-100 mm', 'intensity': 'high'},
                {'stage': 'Fruit Development', 'amount': '80-120 mm', 'intensity': 'medium'},
                {'stage': 'Harvesting', 'amount': '10-30 mm', 'intensity': 'low'},
            ],
        },
        'potato': {
            'total_days': 120,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Planting', 'duration': 7, 'category': 'Critical', 'offset': 10},
                {'name': 'Sprouting', 'duration': 15, 'category': 'Critical', 'offset': 17},
                {'name': 'Vegetative Growth', 'duration': 30, 'category': 'High', 'offset': 32},
                {'name': 'Tuber Initiation', 'duration': 20, 'category': 'Critical', 'offset': 62},
                {'name': 'Tuber Bulking', 'duration': 30, 'category': 'High', 'offset': 82},
                {'name': 'Maturation', 'duration': 18, 'category': 'Normal', 'offset': 112},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 130},
            ],
            'water_total': '500-700 mm',
            'water_stages': [
                {'stage': 'Sprouting', 'amount': '60-80 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '120-150 mm', 'intensity': 'high'},
                {'stage': 'Tuber Initiation', 'amount': '100-150 mm', 'intensity': 'high'},
                {'stage': 'Tuber Bulking', 'amount': '150-200 mm', 'intensity': 'high'},
                {'stage': 'Maturation', 'amount': '70-120 mm', 'intensity': 'medium'},
            ],
        },
        'garlic': {
            'total_days': 150,
            'phases': [
                {'name': 'Land Preparation', 'duration': 10, 'category': 'Treatment', 'offset': 0},
                {'name': 'Planting', 'duration': 7, 'category': 'Critical', 'offset': 10},
                {'name': 'Sprouting', 'duration': 15, 'category': 'Critical', 'offset': 17},
                {'name': 'Vegetative Growth', 'duration': 50, 'category': 'High', 'offset': 32},
                {'name': 'Bulb Formation', 'duration': 40, 'category': 'Critical', 'offset': 82},
                {'name': 'Bulb Enlargement', 'duration': 25, 'category': 'High', 'offset': 122},
                {'name': 'Maturation', 'duration': 13, 'category': 'Normal', 'offset': 147},
                {'name': 'Harvesting', 'duration': 5, 'category': 'Critical', 'offset': 160},
            ],
            'water_total': '350-450 mm',
            'water_stages': [
                {'stage': 'Sprouting', 'amount': '40-60 mm', 'intensity': 'high'},
                {'stage': 'Vegetative Growth', 'amount': '120-150 mm', 'intensity': 'high'},
                {'stage': 'Bulb Formation', 'amount': '100-130 mm', 'intensity': 'high'},
                {'stage': 'Bulb Enlargement', 'amount': '60-80 mm', 'intensity': 'medium'},
                {'stage': 'Maturation', 'amount': '30-50 mm', 'intensity': 'low'},
            ],
        },
    }

    @staticmethod
    def get_soil_advice(soil_type: str, crop_name: str) -> Dict:
        """Get soil-specific advice and recommendations"""
        soil_info = CropGrowthService.SOIL_TYPES.get(soil_type, CropGrowthService.SOIL_TYPES['loamy_moist'])
        
        # Base soil advice
        advice = {
            'description': soil_info['description'],
            'advantages': [],
            'challenges': [],
            'recommendations': []
        }

        # Advantages based on soil type
        if soil_info['fertility'] in ['high', 'very_high']:
            advice['advantages'].append(f"High natural fertility - excellent for {crop_name}")
        if soil_info['water_retention'] == 'high':
            advice['advantages'].append("Good water retention reduces irrigation frequency")
        if soil_info['drainage'] in ['good', 'excellent']:
            advice['advantages'].append("Good drainage prevents waterlogging")

        # Challenges
        if soil_info['drainage'] == 'poor':
            advice['challenges'].append("Poor drainage may cause waterlogging - ensure proper field leveling")
        if soil_info['water_retention'] in ['low', 'very_low']:
            advice['challenges'].append("Low water retention requires frequent irrigation")
        if soil_info['fertility'] == 'low':
            advice['challenges'].append("Low fertility requires regular fertilizer application")

        # Crop-specific recommendations
        crop_specific_tips = {
            'sugarcane': [
                "Apply organic manure before planting",
                "Ensure adequate spacing (90-120 cm) between rows",
                "Regular earthing up after 45-60 days",
            ],
            'cotton': [
                "Deep plowing recommended for better root development",
                "Apply gypsum if soil pH is high",
                "Regular pest monitoring essential",
            ],
            'rice': [
                "Maintain 2-5 cm standing water during vegetative stage",
                "Drain field 10 days before harvest",
                "Apply zinc if deficient",
            ],
            'wheat': [
                "Sow within optimal temperature range (18-25°C)",
                "Apply nitrogen in 2-3 splits",
                "Monitor for rust diseases",
            ],
            'tomato': [
                "Use raised beds for better drainage",
                "Stake or cage plants for support",
                "Monitor for early and late blight",
            ],
            'potato': [
                "Ensure proper hilling for tuber protection",
                "Avoid waterlogging during tuber formation",
                "Store seed potatoes properly before planting",
            ],
        }

        # Add crop-specific recommendations
        if crop_name.lower() in crop_specific_tips:
            advice['recommendations'].extend(crop_specific_tips[crop_name.lower()])
        else:
            advice['recommendations'].extend([
                "Apply balanced NPK fertilizers as per soil test",
                "Maintain proper field hygiene",
                "Follow recommended crop rotation",
            ])

        # Soil-type specific recommendations
        if soil_info['drainage'] == 'poor':
            advice['recommendations'].append("Create drainage channels to prevent waterlogging")
        if soil_info['fertility'] == 'low':
            advice['recommendations'].append("Apply compost or farmyard manure regularly")
        if soil_info['water_retention'] == 'very_low':
            advice['recommendations'].append("Use mulching to reduce water evaporation")

        return advice

    @staticmethod
    def generate_timeline(crop_name: str, soil_type: str = 'loamy_moist', start_date: Optional[datetime] = None) -> Dict:
        """Generate growth timeline for a crop"""
        crop_name_normalized = crop_name.lower().replace(' ', '')
        
        if crop_name_normalized not in CropGrowthService.CROP_TIMELINES:
            return {'success': False, 'message': f'Timeline not available for {crop_name}'}

        crop_data = CropGrowthService.CROP_TIMELINES[crop_name_normalized]
        
        if start_date is None:
            start_date = datetime.now()

        timeline = []
        for i, phase in enumerate(crop_data['phases']):
            phase_start = start_date + timedelta(days=phase['offset'])
            phase_end = phase_start + timedelta(days=phase['duration'])
            
            timeline.append({
                'id': f'phase_{i+1}',
                'task_name': phase['name'],
                'category': phase['category'],
                'start_date': phase_start.strftime('%Y-%m-%d'),
                'end_date': phase_end.strftime('%Y-%m-%d'),
                'duration': phase['duration'],
                'dependencies': f'phase_{i}' if i > 0 else None,
            })

        soil_advice = CropGrowthService.get_soil_advice(soil_type, crop_name)

        return {
            'success': True,
            'crop_name': crop_name,
            'soil_type': soil_type,
            'total_days': crop_data['total_days'],
            'timeline': timeline,
            'soil_advice': soil_advice,
        }

    @staticmethod
    def get_water_consumption(crop_name: str, soil_type: str = 'loamy_moist') -> Dict:
        """Get water consumption data for a crop"""
        crop_name_normalized = crop_name.lower().replace(' ', '')
        
        if crop_name_normalized not in CropGrowthService.CROP_TIMELINES:
            return {'success': False, 'message': f'Water data not available for {crop_name}'}

        crop_data = CropGrowthService.CROP_TIMELINES[crop_name_normalized]
        
        # Adjust water requirements based on soil type
        soil_info = CropGrowthService.SOIL_TYPES.get(soil_type, CropGrowthService.SOIL_TYPES['loamy_moist'])
        
        irrigation_tips = [
            f"Soil type: {soil_info['name']} - {soil_info['water_retention']} water retention",
            "Water early morning or late evening to reduce evaporation",
            "Monitor soil moisture regularly - avoid both overwatering and drought stress",
        ]

        if soil_info['drainage'] == 'poor':
            irrigation_tips.append("Avoid overwatering - ensure proper drainage to prevent waterlogging")
        elif soil_info['water_retention'] in ['low', 'very_low']:
            irrigation_tips.append("Increase irrigation frequency due to low water retention")
            irrigation_tips.append("Consider drip irrigation for water efficiency")
        
        if crop_name_normalized in ['rice']:
            irrigation_tips.append("Maintain standing water during vegetative and reproductive stages")
        elif crop_name_normalized in ['tomato', 'potato', 'onion']:
            irrigation_tips.append("Use drip or furrow irrigation for efficient water use")
        
        irrigation_tips.extend([
            "Apply mulch to conserve soil moisture",
            "Adjust watering based on rainfall and weather conditions",
        ])

        return {
            'success': True,
            'crop_name': crop_name,
            'soil_type': soil_type,
            'total_water': crop_data['water_total'],
            'stages': crop_data['water_stages'],
            'irrigation_tips': irrigation_tips,
        }
