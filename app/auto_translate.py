"""
Auto-Translation Updater for FarmOps Flutter App
This script automatically adds translations to all Flutter pages
"""

import os
import re

# Mapping of common English strings to translation keys
TRANSLATIONS_MAP = {
    # Common actions
    "'Submit'": "context.localizations.submit",
    "'Cancel'": "context.localizations.cancel",
    "'Save'": "context.localizations.save",
    "'Delete'": "context.localizations.delete",
    "'Edit'": "context.localizations.edit",
    "'Next'": "context.localizations.next",
    "'Yes'": "context.localizations.yes",
    "'No'": "context.localizations.no",
    "'Close'": "context.localizations.close",
    "'Retry'": "context.localizations.retry",
    "'Send'": "context.localizations.send",
    
    # Status
    "'Loading...'": "context.localizations.loading",
    "'Error'": "context.localizations.error",
    "'Success'": "context.localizations.success",
    
    # Navigation
    "'Home'": "context.localizations.home",
    "'Profile'": "context.localizations.profile",
    "'Logout'": "context.localizations.logout",
    
    # Authentication
    "'Mobile Number'": "context.localizations.mobileNumber",
    "'Enter your Mobile Number'": "context.localizations.enterMobileNumber",
    "'Get OTP'": "context.localizations.getOTP",
    "'Verify OTP'": "context.localizations.verifyOTP",
    "'Verify'": "context.localizations.verify",
    "'Resend OTP'": "context.localizations.resendOTP",
    
    # Profile
    "'My Profile'": "context.localizations.myProfile",
    "'Name'": "context.localizations.name",
    "'Location'": "context.localizations.location",
    "'Land Size'": "context.localizations.landSize",
    "'Edit Profile'": "context.localizations.editProfile",
    "'Save Profile'": "context.localizations.saveProfile",
    
    # Soil parameters
    "'Nitrogen'": "context.localizations.nitrogen",
    "'Phosphorus'": "context.localizations.phosphorus",
    "'Potassium'": "context.localizations.potassium",
    "'Temperature'": "context.localizations.temperature",
    "'Humidity'": "context.localizations.humidity",
    "'pH Level'": "context.localizations.ph",
    "'Rainfall'": "context.localizations.rainfall",
    
    # Weather
    "'Current Weather'": "context.localizations.currentWeather",
    "'Forecast'": "context.localizations.forecast",
    "'Feels Like'": "context.localizations.feelsLike",
    "'Wind'": "context.localizations.wind",
    "'Pressure'": "context.localizations.pressure",
    
    # Disease Detection
    "'Upload Image'": "context.localizations.uploadImage",
    "'Take Photo'": "context.localizations.takePhoto",
    "'Analyzing...'": "context.localizations.analyzing",
    "'Disease Detected'": "context.localizations.diseaseDetected",
    "'Treatment'": "context.localizations.treatment",
    
    # Market
    "'Current Prices'": "context.localizations.currentPrices",
    "'Price History'": "context.localizations.priceHistory",
    "'Crop Name'": "context.localizations.cropName",
    "'Price'": "context.localizations.price",
    
    # Calculator
    "'Crop Cost'": "context.localizations.cropCost",
    "'Selling Price'": "context.localizations.sellingPrice",
    "'Calculate'": "context.localizations.calculate",
    "'Profit'": "context.localizations.profit",
    "'Loss'": "context.localizations.loss",
}

def add_import_if_missing(content):
    """Add localization import if not present"""
    if "import 'services/localization_service.dart';" not in content:
        # Find the last import statement
        import_pattern = r"(import\s+['\"].*?['\"];)"
        imports = list(re.finditer(import_pattern, content))
        if imports:
            last_import = imports[-1]
            insert_pos = last_import.end()
            content = (
                content[:insert_pos] + 
                "\nimport 'services/localization_service.dart';" +
                content[insert_pos:]
            )
    return content

def update_file(filepath):
    """Update a single file with translations"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Add import
        content = add_import_if_missing(content)
        
        # Replace text strings
        for english, translation in TRANSLATIONS_MAP.items():
            # Handle Text() widgets
            pattern1 = f"Text\\({english}"
            replacement1 = f"Text({translation}"
            content = re.sub(pattern1, replacement1, content)
            
            # Handle hintText, labelText, etc in InputDecoration
            pattern2 = f"(hintText|labelText|helperText):\\s*{english}"
            replacement2 = f"\\1: {translation}"
            content = re.sub(pattern2, replacement2, content)
            
            # Handle child: Text()
            pattern3 = f"child:\\s*Text\\({english}"
            replacement3 = f"child: Text({translation}"
            content = re.sub(pattern3, replacement3, content)
        
        # Only write if changes were made
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error updating {filepath}: {e}")
        return False

def main():
    """Main function to update all Dart files"""
    lib_dir = "lib"
    updated_files = []
    skipped_files = []
    
    # Get all .dart files in lib directory
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                
                # Skip certain files
                if any(skip in filepath for skip in ['services/', 'widgets/', 'examples/']):
                    continue
                
                print(f"Processing: {filepath}")
                if update_file(filepath):
                    updated_files.append(filepath)
                    print(f"  ✓ Updated")
                else:
                    skipped_files.append(filepath)
                    print(f"  - No changes needed")
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Updated: {len(updated_files)} files")
    print(f"  Skipped: {len(skipped_files)} files")
    print(f"{'='*60}")
    
    if updated_files:
        print("\nUpdated files:")
        for f in updated_files:
            print(f"  - {f}")

if __name__ == "__main__":
    main()
