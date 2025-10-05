"""
Remove unused localization imports
"""

import os
import re

def remove_unused_imports(filepath):
    """Remove unused localization imports from a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Check if file actually uses context.localizations
        if 'context.localizations' not in content:
            # Remove the import
            content = re.sub(
                r"import\s+['\"]\.\.?/?services/localization_service\.dart['\"];\n?",
                "",
                content
            )
            content = re.sub(
                r"import\s+['\"]localization_service\.dart['\"];\n?",
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
        print(f"Error cleaning {filepath}: {e}")
        return False

def main():
    """Main function to clean all Dart files"""
    lib_dir = "lib"
    cleaned_files = []
    
    # Get all .dart files in lib directory
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                
                if remove_unused_imports(filepath):
                    cleaned_files.append(filepath)
                    print(f"✓ Cleaned: {filepath}")
    
    print(f"\n{'='*60}")
    print(f"Summary: Cleaned {len(cleaned_files)} files")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
