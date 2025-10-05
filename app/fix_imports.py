"""
Fix import paths for service and widget files
"""

import os
import re

def fix_imports_in_file(filepath):
    """Fix import paths in a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Determine if file is in services/ or widgets/ directory
        if 'services\\' in filepath or 'services/' in filepath:
            # For files in services/, use relative import
            content = re.sub(
                r"import 'services/localization_service\.dart';",
                "import 'localization_service.dart';",
                content
            )
        elif 'widgets\\' in filepath or 'widgets/' in filepath:
            # For files in widgets/, use parent directory import  
            content = re.sub(
                r"import 'services/localization_service\.dart';",
                "import '../services/localization_service.dart';",
                content
            )
        
        # Remove the erroneous self-import from localization_service.dart
        if 'localization_service.dart' in filepath:
            content = re.sub(
                r"import 'services/localization_service\.dart';\n?",
                "",
                content
            )
            content = re.sub(
                r"import 'localization_service\.dart';\n?",
                "",
                content
            )
        
        # Only write if changes were made
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error fixing {filepath}: {e}")
        return False

def main():
    """Main function to fix all Dart files"""
    lib_dir = "lib"
    fixed_files = []
    
    # Get all .dart files in lib directory
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                
                print(f"Checking: {filepath}")
                if fix_imports_in_file(filepath):
                    fixed_files.append(filepath)
                    print(f"  ✓ Fixed")
                else:
                    print(f"  - OK")
    
    print(f"\n{'='*60}")
    print(f"Summary: Fixed {len(fixed_files)} files")
    print(f"{'='*60}")
    
    if fixed_files:
        print("\nFixed files:")
        for f in fixed_files:
            print(f"  - {f}")

if __name__ == "__main__":
    main()
