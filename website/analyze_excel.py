#!/usr/bin/env python3
"""
Excel File Analysis Script - Examine location-based soil data structure
"""

import pandas as pd
import sys

def analyze_excel_structure():
    """Analyze the Excel file to understand location and nutrient data structure"""
    
    try:
        # Read the Excel file
        excel_file = r"C:\Users\harsh\Desktop\INNOVIK\cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        
        print("📊 EXCEL FILE ANALYSIS")
        print("=" * 50)
        
        # Basic info
        print(f"📋 Shape: {df.shape[0]} rows, {df.shape[1]} columns")
        print(f"📝 Columns: {list(df.columns)}")
        
        # Sample data
        print("\n🔍 First 3 rows:")
        print(df.head(3).to_string())
        
        # Check for location columns
        location_cols = [col for col in df.columns if any(word in col.lower() for word in ['state', 'district', 'block', 'village', 'location', 'place'])]
        print(f"\n📍 Location Columns Found: {location_cols}")
        
        # Check for nutrient columns
        nutrient_cols = [col for col in df.columns if any(word in col.lower() for word in ['nitrogen', 'n', 'phosphorus', 'p', 'potassium', 'k', 'ph', 'ec', 'oc', 'organic', 'zinc', 'iron', 'boron', 'copper', 'sulphur', 'manganese'])]
        print(f"🧪 Nutrient Columns Found: {nutrient_cols}")
        
        # Check for unique locations
        if location_cols:
            main_location_col = location_cols[0]
            unique_locations = df[main_location_col].unique()[:10]  # First 10
            print(f"\n🌍 Sample Locations from '{main_location_col}': {unique_locations}")
        
        # Check data types
        print(f"\n📊 Data Types:")
        print(df.dtypes.to_string())
        
        # Check for missing values in key columns
        if nutrient_cols:
            print(f"\n❓ Missing Values in Nutrient Columns:")
            for col in nutrient_cols[:5]:  # First 5 nutrient columns
                missing = df[col].isnull().sum()
                total = len(df)
                print(f"   {col}: {missing}/{total} missing ({missing/total*100:.1f}%)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error analyzing Excel file: {str(e)}")
        return False

if __name__ == "__main__":
    try:
        analyze_excel_structure()
    except KeyboardInterrupt:
        print("\n\n⚠️  Analysis interrupted by user")
    except Exception as e:
        print(f"\n❌ Analysis failed: {str(e)}")