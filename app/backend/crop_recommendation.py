"""
Crop Recommendation Module
Handles location-based crop prediction and soil-based recommendations
"""
import pandas as pd
from typing import Dict, List, Any, Optional
import os


class CropRecommendationService:
    """Service for crop recommendations based on location and soil data"""
    
    def __init__(self, excel_path: str = "cropresults_with_state.xlsx"):
        """
        Initialize the service with Excel data
        
        Args:
            excel_path: Path to the Excel file with crop data
        """
        self.excel_path = excel_path
        self.df = None
        self.dropdown_data = {}
        self._load_data()
    
    def _load_data(self):
        """Load and prepare Excel data"""
        try:
            if not os.path.exists(self.excel_path):
                print(f"⚠️ Excel file not found: {self.excel_path}")
                print("Using sample data for demonstration")
                self._create_sample_data()
                return
            
            self.df = pd.read_excel(self.excel_path)
            
            # Clean column names
            self.df.columns = [col.strip() for col in self.df.columns]
            
            # Forward fill and backward fill location columns
            location_cols = ['STATE', 'DISTRICT NAME', 'BLOCK NAME', 'VILLAGE NAME']
            self.df[location_cols] = (
                self.df[location_cols]
                .ffill()
                .bfill()
                .astype(str)
            )
            
            # Build dropdown hierarchy
            self._build_dropdown_hierarchy()
            
            print(f"✓ Loaded crop data: {len(self.df)} rows")
            print(f"✓ States: {len(self.dropdown_data)}")
            
        except Exception as e:
            print(f"✗ Error loading Excel data: {e}")
            self._create_sample_data()
    
    def _create_sample_data(self):
        """Create sample data for demonstration"""
        # Sample data structure
        sample_data = {
            'STATE': ['Maharashtra', 'Maharashtra', 'Karnataka', 'Karnataka'],
            'DISTRICT NAME': ['Pune', 'Pune', 'Bangalore', 'Bangalore'],
            'BLOCK NAME': ['Haveli', 'Mulshi', 'North', 'South'],
            'VILLAGE NAME': ['Katraj', 'Paud', 'Yelahanka', 'Jayanagar'],
            'Sugarcane': ['Highly Suitable', 'Moderately Suitable', 'Not Suitable', 'Moderately Suitable'],
            'Cotton': ['Moderately Suitable', 'Highly Suitable', 'Not Suitable', 'Moderately Suitable'],
            'Rice': ['Highly Suitable', 'Highly Suitable', 'Moderately Suitable', 'Highly Suitable'],
            'Wheat': ['Moderately Suitable', 'Highly Suitable', 'Moderately Suitable', 'Highly Suitable'],
        }
        
        self.df = pd.DataFrame(sample_data)
        self._build_dropdown_hierarchy()
        print("✓ Created sample crop data")
    
    def _build_dropdown_hierarchy(self):
        """Build hierarchical dropdown data structure"""
        self.dropdown_data = {}
        
        for _, row in self.df.iterrows():
            state = row['STATE']
            district = row['DISTRICT NAME']
            block = row['BLOCK NAME']
            village = row['VILLAGE NAME']
            
            # Initialize nested dictionaries
            if state not in self.dropdown_data:
                self.dropdown_data[state] = {}
            
            if district not in self.dropdown_data[state]:
                self.dropdown_data[state][district] = {}
            
            if block not in self.dropdown_data[state][district]:
                self.dropdown_data[state][district][block] = []
            
            # Add village if not already present
            if village not in self.dropdown_data[state][district][block]:
                self.dropdown_data[state][district][block].append(village)
    
    def get_states(self) -> List[str]:
        """Get list of all states"""
        return sorted(list(self.dropdown_data.keys()))
    
    def get_districts(self, state: str) -> List[str]:
        """Get list of districts for a state"""
        if state not in self.dropdown_data:
            return []
        return sorted(list(self.dropdown_data[state].keys()))
    
    def get_blocks(self, state: str, district: str) -> List[str]:
        """Get list of blocks for a district"""
        if state not in self.dropdown_data:
            return []
        if district not in self.dropdown_data[state]:
            return []
        return sorted(list(self.dropdown_data[state][district].keys()))
    
    def get_villages(self, state: str, district: str, block: str) -> List[str]:
        """Get list of villages for a block"""
        if state not in self.dropdown_data:
            return []
        if district not in self.dropdown_data[state]:
            return []
        if block not in self.dropdown_data[state][district]:
            return []
        return sorted(self.dropdown_data[state][district][block])
    
    def get_dropdown_data(self) -> Dict[str, Any]:
        """Get complete dropdown hierarchy"""
        return self.dropdown_data
    
    def get_crop_suitability(self, state: str, district: str, block: str, village: str) -> Optional[Dict[str, str]]:
        """
        Get crop suitability data for a specific location
        
        Returns:
            Dictionary with crop names as keys and suitability as values
        """
        if self.df is None:
            return None
        
        # Find the row matching the location
        row = self.df[
            (self.df['STATE'] == state) &
            (self.df['DISTRICT NAME'] == district) &
            (self.df['BLOCK NAME'] == block) &
            (self.df['VILLAGE NAME'] == village)
        ]
        
        if row.empty:
            return None
        
        # Extract crop columns
        crop_columns = [
            'Sugarcane', 'Cotton', 'Soyabean', 'Rice', 'Jowar',
            'Tur (Pigeon Pea)', 'Wheat', 'Groundnut', 'Onion', 'Tomato',
            'Potato', 'Garlic'
        ]
        
        # Get crop suitability data
        crop_data = {}
        for col in crop_columns:
            if col in row.columns:
                crop_data[col] = row.iloc[0][col]
        
        return crop_data
    
    @staticmethod
    def normalize_input(input_data: Dict[str, str]) -> Dict[str, str]:
        """
        Normalize input data by extracting category from full text
        
        Args:
            input_data: Dictionary with attribute names and full values
            
        Returns:
            Dictionary with normalized values (High/Medium/Low etc.)
        """
        value_map = {
            "High (81–100%)": "High",
            "Medium (51–80%)": "Medium",
            "Low (0–50%)": "Low",
            "Medium (41–80%)": "Medium",
            "Low (0–40%)": "Low",
            "Medium (31–80%)": "Medium",
            "Low (0–30%)": "Low",
            "High (> 0.75%)": "High",
            "Medium (0.5–0.75%)": "Medium",
            "Low (< 0.5%)": "Low",
            "Non-Saline (< 4 dS/m)": "Non-Saline",
            "Saline (≥ 4 dS/m)": "Saline",
            "Neutral (6.5–7.5)": "Neutral",
            "Alkaline (above 7.5)": "Alkaline",
            "Acidic (below 6.5)": "Acidic",
            "Sufficient (81–100%)": "Sufficient",
            "Deficient (0–50%)": "Deficient",
            "Sufficient (86–100%)": "Sufficient",
            "Deficient (0–60%)": "Deficient",
            "Low (< 28°C – Too cool for summer crops)": "Low",
            "Medium (28–35°C – Ideal for warm-season crops)": "Medium",
            "High (> 35°C – Heat stress risk)": "High",
            "Low (< 10°C – Too cold for most crops)": "Low",
            "Medium (10–20°C – Ideal for rabi crops)": "Medium",
            "High (> 20°C – May hinder wheat filling)": "High",
            "Low (< 22°C – Poor germination)": "Low",
            "Medium (22–30°C – Ideal for kharif crops)": "Medium",
            "High (> 30°C – Fungal stress risk)": "High",
            "High (1000–1500 mm – Ideal rainfed range)": "High",
            "Medium (500–1000 mm – May need irrigation)": "Medium",
            "Low (< 500 mm – Highly insufficient)": "Low"
        }
        
        normalized = {}
        for key, value in input_data.items():
            key = key.strip()
            value = value.strip()
            normalized[key] = value_map.get(value, value)
        
        return normalized
    
    @staticmethod
    def evaluate_all_crops(data: Dict[str, str]) -> Dict[str, str]:
        """
        Evaluate suitability for all crops based on soil and climate data
        
        Args:
            data: Normalized input data
            
        Returns:
            Dictionary with crop names and suitability levels
        """
        # Handle Rainfall field name variations
        if "Rainfall overall" in data:
            data["Rainfall"] = data.pop("Rainfall overall")
        
        results = {}
        
        # Sugarcane
        cnt = sum([
            data.get('Nitrogen') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('OC') in ["High", "Medium"],
            data.get('EC') == "Non-Saline",
            data.get('pH') in ["Neutral", "Alkaline"],
            data.get('Temperature_Winter') == "High",
            data.get('Rainfall') in ["High", "Medium"]
        ])
        results["Sugarcane"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")
        
        # Cotton
        cnt = sum([
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('Zinc') == "Sufficient",
            data.get('pH') in ["Neutral", "Alkaline"],
            data.get('Temperature_Winter') == "High",
            data.get('Rainfall') in ["High", "Medium"]
        ])
        results["Cotton"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        # Soyabean
        cnt = sum([
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('Boron') == "Sufficient",
            data.get('Sulphur') == "Sufficient",
            data.get('OC') in ["High", "Medium"],
            data.get('pH') in ["Neutral", "Acidic"],
            data.get('Rainfall') in ["High", "Medium"]
        ])
        results["Soyabean"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        # Rice
        cnt = sum([
            data.get('Nitrogen') in ["High", "Medium"],
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('pH') in ["Neutral", "Acidic", "Alkaline"],
            data.get('EC') == "Non-Saline",
            data.get('Temperature_Winter') == "High",
            data.get('Rainfall') == "High",
            data.get('Boron') == "Sufficient" or data.get('Copper') == "Sufficient"
        ])
        results["Rice"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        # Jowar
        cnt = sum([
            data.get('Potassium') in ["High", "Medium"],
            data.get('Zinc') == "Sufficient",
            data.get('EC') == "Non-Saline",
            data.get('pH') in ["Neutral", "Alkaline"],
            data.get('Temperature_Winter') == "High",
            data.get('Rainfall') == "Medium"
        ])
        results["Jowar"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        # Tur (Pigeon Pea)
        cnt = sum([
            data.get('Phosphorus') in ["High", "Medium", "Low"],
            data.get('OC') in ["High", "Medium"],
            data.get('Iron') == "Sufficient",
            data.get('pH') in ["Neutral", "Alkaline", "Acidic"],
            data.get('Temperature_Winter') == "High",
            data.get('Rainfall') in ["High", "Medium"]
        ])
        results["Tur (Pigeon Pea)"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        # Wheat
        cnt = sum([
            data.get('Nitrogen') in ["High", "Medium"],
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('Zinc') == "Sufficient",
            data.get('Iron') == "Sufficient",
            data.get('Manganese') == "Sufficient",
            data.get('pH') == "Neutral",
            data.get('Temperature_Monsoon') == "Medium",
            data.get('Rainfall') in ["High", "Medium"]
        ])
        results["Wheat"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")
        
        # Groundnut
        cnt = sum([
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('Boron') == "Sufficient",
            data.get('EC') == "Non-Saline",
            data.get('pH') == "Neutral",
            data.get('Temperature_Winter') == "High",
            data.get('Rainfall') == "Medium"
        ])
        results["Groundnut"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")
        
        # Onion
        cnt = sum([
            data.get('Potassium') in ["High", "Medium"],
            data.get('Sulphur') == "Sufficient",
            data.get('Zinc') == "Sufficient",
            data.get('OC') in ["High", "Medium"],
            any(t in ["High", "Medium"] for t in [
                data.get('Temperature_Summer', ''),
                data.get('Temperature_Winter', ''),
                data.get('Temperature_Monsoon', '')
            ])
        ])
        results["Onion"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt >= 3 else "Not Suitable")
        
        # Tomato
        cnt = sum([
            data.get('Nitrogen') in ["High", "Medium"],
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('Zinc') == "Sufficient",
            data.get('Boron') == "Sufficient",
            any(t in ["High", "Medium"] for t in [
                data.get('Temperature_Summer', ''),
                data.get('Temperature_Winter', ''),
                data.get('Temperature_Monsoon', '')
            ])
        ])
        results["Tomato"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        # Potato
        cnt = sum([
            data.get('Nitrogen') in ["High", "Medium"],
            data.get('Phosphorus') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('EC') == "Non-Saline",
            data.get('pH') in ["Neutral", "Alkaline"],
            data.get('Temperature_Summer', '') in ["High", "Medium"],
            data.get('Temperature_Monsoon', '') in ["High", "Medium"]
        ])
        results["Potato"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")
        
        # Garlic
        cnt = sum([
            data.get('Nitrogen') in ["High", "Medium"],
            data.get('Potassium') in ["High", "Medium"],
            data.get('OC') in ["High", "Medium"],
            data.get('pH') in ["Neutral", "Alkaline"],
            data.get('Zinc') == "Sufficient",
            data.get('Temperature_Winter', '') in ["High", "Medium"],
            data.get('Rainfall') in ["High", "Medium"]
        ])
        results["Garlic"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")
        
        return results
