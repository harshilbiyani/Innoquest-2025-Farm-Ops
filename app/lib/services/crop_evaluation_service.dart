class CropEvaluationService {
  // Normalize input values to simple categories
  static Map<String, String> normalizeInput(Map<String, String> input) {
    final valueMap = {
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
      "Low (< 500 mm – Highly insufficient)": "Low",
    };

    Map<String, String> normalized = {};
    input.forEach((key, value) {
      normalized[key] = valueMap[value] ?? value;
    });

    return normalized;
  }

  // Evaluate all crops based on normalized input
  static Map<String, String> evaluateAllCrops(Map<String, String> input) {
    Map<String, String> normalized = normalizeInput(input);
    Map<String, String> results = {};

    // Helper function to count matching conditions
    int countMatches(List<bool> conditions) {
      return conditions.where((c) => c).length;
    }

    // Sugarcane
    int cnt = countMatches([
      ["High", "Medium"].contains(normalized['Nitrogen']),
      ["High", "Medium"].contains(normalized['Potassium']),
      ["High", "Medium"].contains(normalized['OC']),
      normalized['EC'] == "Non-Saline",
      ["Neutral", "Alkaline"].contains(normalized['pH']),
      normalized['Temperature_Winter'] == "High",
      ["High", "Medium"].contains(normalized['Rainfall']),
    ]);
    results["Sugarcane"] = cnt >= 6
        ? "Highly Suitable"
        : (cnt == 5 ? "Moderately Suitable" : "Not Suitable");

    // Cotton
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Phosphorus']),
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['Zinc'] == "Sufficient",
      ["Neutral", "Alkaline"].contains(normalized['pH']),
      normalized['Temperature_Winter'] == "High",
      ["High", "Medium"].contains(normalized['Rainfall']),
    ]);
    results["Cotton"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    // Soyabean
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Phosphorus']),
      normalized['Boron'] == "Sufficient",
      normalized['Sulphur'] == "Sufficient",
      ["High", "Medium"].contains(normalized['OC']),
      ["Neutral", "Acidic"].contains(normalized['pH']),
      ["High", "Medium"].contains(normalized['Rainfall']),
    ]);
    results["Soyabean"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    // Rice
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Nitrogen']),
      ["High", "Medium"].contains(normalized['Phosphorus']),
      ["Neutral", "Acidic", "Alkaline"].contains(normalized['pH']),
      normalized['EC'] == "Non-Saline",
      normalized['Temperature_Winter'] == "High",
      normalized['Rainfall'] == "High",
      normalized['Boron'] == "Sufficient" ||
          normalized['Copper'] == "Sufficient",
    ]);
    results["Rice"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    // Jowar
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['Zinc'] == "Sufficient",
      normalized['EC'] == "Non-Saline",
      ["Neutral", "Alkaline"].contains(normalized['pH']),
      normalized['Temperature_Winter'] == "High",
      normalized['Rainfall'] == "Medium",
    ]);
    results["Jowar"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    // Tur (Pigeon Pea)
    cnt = countMatches([
      ["High", "Medium", "Low"].contains(normalized['Phosphorus']),
      ["High", "Medium"].contains(normalized['OC']),
      normalized['Iron'] == "Sufficient",
      ["Neutral", "Alkaline", "Acidic"].contains(normalized['pH']),
      normalized['Temperature_Winter'] == "High",
      ["High", "Medium"].contains(normalized['Rainfall']),
    ]);
    results["Tur (Pigeon Pea)"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    // Wheat
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Nitrogen']),
      ["High", "Medium"].contains(normalized['Phosphorus']),
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['Zinc'] == "Sufficient",
      normalized['Iron'] == "Sufficient",
      normalized['Manganese'] == "Sufficient",
      normalized['pH'] == "Neutral",
      normalized['Temperature_Monsoon'] == "Medium",
      ["High", "Medium"].contains(normalized['Rainfall']),
    ]);
    results["Wheat"] = cnt >= 6
        ? "Highly Suitable"
        : (cnt == 5 ? "Moderately Suitable" : "Not Suitable");

    // Groundnut
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Phosphorus']),
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['Boron'] == "Sufficient",
      normalized['EC'] == "Non-Saline",
      normalized['pH'] == "Neutral",
      normalized['Temperature_Winter'] == "High",
      normalized['Rainfall'] == "Medium",
    ]);
    results["Groundnut"] = cnt >= 6
        ? "Highly Suitable"
        : (cnt == 5 ? "Moderately Suitable" : "Not Suitable");

    // Onion
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['Sulphur'] == "Sufficient",
      normalized['Zinc'] == "Sufficient",
      ["High", "Medium"].contains(normalized['OC']),
      ["High", "Medium"].contains(normalized['Temperature_Summer']) ||
          ["High", "Medium"].contains(normalized['Temperature_Winter']) ||
          ["High", "Medium"].contains(normalized['Temperature_Monsoon']),
    ]);
    results["Onion"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt >= 3 ? "Moderately Suitable" : "Not Suitable");

    // Tomato
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Nitrogen']),
      ["High", "Medium"].contains(normalized['Phosphorus']),
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['Zinc'] == "Sufficient",
      normalized['Boron'] == "Sufficient",
      ["High", "Medium"].contains(normalized['Temperature_Summer']) ||
          ["High", "Medium"].contains(normalized['Temperature_Winter']) ||
          ["High", "Medium"].contains(normalized['Temperature_Monsoon']),
    ]);
    results["Tomato"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    // Potato
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Nitrogen']),
      ["High", "Medium"].contains(normalized['Phosphorus']),
      ["High", "Medium"].contains(normalized['Potassium']),
      normalized['EC'] == "Non-Saline",
      ["Neutral", "Alkaline"].contains(normalized['pH']),
      ["High", "Medium"].contains(normalized['Temperature_Summer']),
      ["High", "Medium"].contains(normalized['Temperature_Monsoon']),
    ]);
    results["Potato"] = cnt >= 6
        ? "Highly Suitable"
        : (cnt == 5 ? "Moderately Suitable" : "Not Suitable");

    // Garlic
    cnt = countMatches([
      ["High", "Medium"].contains(normalized['Nitrogen']),
      ["High", "Medium"].contains(normalized['Potassium']),
      ["High", "Medium"].contains(normalized['OC']),
      ["Neutral", "Alkaline"].contains(normalized['pH']),
      normalized['Zinc'] == "Sufficient",
      ["High", "Medium"].contains(normalized['Temperature_Winter']),
      ["High", "Medium"].contains(normalized['Rainfall']),
    ]);
    results["Garlic"] = cnt >= 5
        ? "Highly Suitable"
        : (cnt == 4 ? "Moderately Suitable" : "Not Suitable");

    return results;
  }

  // Get crop icon path
  static String getCropIcon(String cropName) {
    final cropIcons = {
      "Sugarcane": "assets/images/sugar-cane.png",
      "Cotton": "assets/images/cotton.png",
      "Soyabean": "assets/images/soyabean.png",
      "Rice": "assets/images/rice.png",
      "Jowar": "assets/images/jowar.png",
      "Tur (Pigeon Pea)": "assets/images/pigeonpea.png",
      "Wheat": "assets/images/wheat.png",
      "Groundnut": "assets/images/groundnut.png",
      "Onion": "assets/images/onion.png",
      "Tomato": "assets/images/tomato.png",
      "Potato": "assets/images/potato.png",
      "Garlic": "assets/images/garlic.png",
    };
    return cropIcons[cropName] ?? "assets/images/farmops_logo.png";
  }
}
