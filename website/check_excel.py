import pandas as pd

# Read the Excel file
df = pd.read_excel("cropresults_with_state (1).xlsx")

print("Columns:", df.columns.tolist())
print("\nShape:", df.shape)
print("\nFirst 3 rows:")
print(df.head(3))

# Check for location data
location_columns = [col for col in df.columns if any(word in col.lower() for word in ['state', 'district', 'block', 'village'])]
print("\nLocation columns:", location_columns)

# Check for crop data
crop_columns = [col for col in df.columns if any(word in col.lower() for word in ['crop', 'plant', 'seed'])]
print("Crop columns:", crop_columns)

# Show unique values in key columns
for col in location_columns[:4]:  # First 4 location columns
    if col in df.columns:
        unique_vals = df[col].unique()
        print(f"\nUnique values in {col} ({len(unique_vals)}): {unique_vals[:10]}")