import os
import json
from pathlib import Path
from flask import Flask, render_template, request, jsonify, flash, redirect, url_for, session, send_from_directory
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import requests
from dotenv import load_dotenv
from openai import OpenAI

print("🔦 Importing required libraries...")

# ---------------------------
# Config & Initialization
# ---------------------------

ROOT = Path(__file__).parent
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "gpt-4o-mini")

if not OPENAI_API_KEY:
    raise RuntimeError("❌ OPENAI_API_KEY not set in .env or environment variables")

client = OpenAI(api_key=OPENAI_API_KEY)
app = Flask(__name__, static_folder="static", template_folder="templates")

# Set a secret key for session management (change this to a random secret key in production)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "your-secret-key-change-this-in-production")

# ---------------------------
# User Authentication Functions
# ---------------------------

def is_user_logged_in():
    """Check if user is logged in"""
    return session.get('logged_in', False)

def require_login(f):
    """Decorator to require login for routes"""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not is_user_logged_in():
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def validate_phone_number(phone, country_code='+91'):
    """Validate phone number based on country code"""
    import re
    # Remove any non-digit characters
    clean_phone = re.sub(r'\D', '', phone)

    # Validate based on country code
    if country_code == '+91':  # India
        return bool(re.match(r'^[6-9]\d{9}$', clean_phone))
    elif country_code == '+1':  # US/Canada
        return bool(re.match(r'^\d{10}$', clean_phone))
    elif country_code == '+44':  # UK
        return bool(re.match(r'^\d{10,11}$', clean_phone))
    elif country_code == '+86':  # China
        return bool(re.match(r'^\d{11}$', clean_phone))
    elif country_code == '+81':  # Japan
        return bool(re.match(r'^\d{10,11}$', clean_phone))
    else:
        return len(clean_phone) >= 10

# ---------------------------
# Load Excel Data (shared by site + chatbot)
# ---------------------------

EXCEL_PATH = "cropresults_with_state (1).xlsx"
try:
    print("📊 Loading Excel data...")
    df = pd.read_excel(EXCEL_PATH)
    df.columns = [col.strip() for col in df.columns]
    df[['STATE', 'DISTRICT NAME', 'BLOCK NAME', 'VILLAGE NAME']] = (
        df[['STATE', 'DISTRICT NAME', 'BLOCK NAME', 'VILLAGE NAME']]
        .ffill()
        .bfill()
        .astype(str)
    )
    print("✅ Excel data loaded successfully!")
except Exception as e:
    print(f"⚠️ Warning: Could not load Excel file: {e}")
    # Create empty DataFrame as fallback
    df = pd.DataFrame()
    print("🔄 Running with limited functionality...")

# ---------------------------
# Build Dropdown Hierarchy for Site
# ---------------------------

dropdown_data = {}
if not df.empty:
    try:
        for _, row in df.iterrows():
            state = row['STATE']
            district = row['DISTRICT NAME']
            block = row['BLOCK NAME']
            village = row['VILLAGE NAME']
            dropdown_data.setdefault(state, {})
            dropdown_data[state].setdefault(district, {})
            dropdown_data[state][district].setdefault(block, [])
            if village not in dropdown_data[state][district][block]:
                dropdown_data[state][district][block].append(village)
        print("🗺️ Location hierarchy built successfully!")
    except Exception as e:
        print(f"⚠️ Warning: Could not build location hierarchy: {e}")
        dropdown_data = {}
else:
    print("⚠️ No Excel data available - location features will be limited")

# ---------------------------
# OpenAI Chat Completion Calls with Fallback
# ---------------------------

CHATBOT_COOLDOWN_UNTIL = None

def call_llm(messages, model=None):
    """
    Call OpenAI chat completion with a preferred model, fallback on failure.
    """
    model = model or DEFAULT_MODEL
    global CHATBOT_COOLDOWN_UNTIL
    try:
        resp = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.1,
            max_tokens=600
        )
        return resp.choices[0].message.content.strip()
    except Exception as e:
        print(f"⚠️ Primary model {model} failed: {e}")
        try:
            resp = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=messages,
                temperature=0.3,
                max_tokens=600
            )
            return resp.choices[0].message.content.strip()
        except Exception as e2:
            print(f"❌ Fallback model gpt-3.5-turbo also failed: {e2}")
            error_message = str(e2).lower()
            if "rate limit" in error_message or "too many requests" in error_message:
                if not CHATBOT_COOLDOWN_UNTIL or datetime.now() > CHATBOT_COOLDOWN_UNTIL:
                    CHATBOT_COOLDOWN_UNTIL = datetime.now() + timedelta(seconds=60)
                return get_cooldown_message()
            return "❌ Sorry, chatbot service is temporarily unavailable."

def get_cooldown_message():
    global CHATBOT_COOLDOWN_UNTIL
    if CHATBOT_COOLDOWN_UNTIL:
        now = datetime.now()
        remaining = (CHATBOT_COOLDOWN_UNTIL - now).total_seconds()
        if remaining > 0:
            mins, secs = divmod(int(remaining), 60)
            return f"❌ Sorry, chatbot service is temporarily unavailable. Please try again in {mins}m {secs}s."
        else:
            CHATBOT_COOLDOWN_UNTIL = None
    return "❌ Sorry, chatbot service is temporarily unavailable. Please try again soon."

# ---------------------------
# System Prompt & Prompt Composition for Chatbot
# ---------------------------

SYSTEM_PROMPT = (
    "You are AgroAssist, an expert agricultural assistant for India. "
    "Use the provided SOURCES (if any) to ground your responses. "
    "Cite dataset rows in square brackets like [SOURCE: excel_12_0]. "
    "Answer clearly with actionable steps. "
)

def compose_prompt(user_question, tone="farmer"):
    tone_instr = "Use simple clear language for farmers." if tone == "farmer" else "Use technical agronomy language."
    user_prompt = f"{SYSTEM_PROMPT}\n\n{tone_instr}\n\nUser question: {user_question}"
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt}
    ]

# ---------------------------
# Input Normalization and Crop Evaluation Logic
# ---------------------------

def normalize_input(d):
    value_map = {
        "High (81—100%)": "High", "Medium (51—80%)": "Medium", "Low (0—50%)": "Low",
        "Medium (41—80%)": "Medium", "Low (0—40%)": "Low",
        "Medium (31—80%)": "Medium", "Low (0—30%)": "Low",
        "High (> 0.75%)": "High", "Medium (0.5—0.75%)": "Medium", "Low (< 0.5%)": "Low",
        "Non-Saline (< 4 dS/m)": "Non-Saline", "Saline (≥ 4 dS/m)": "Saline",
        "Neutral (6.5—7.5)": "Neutral", "Alkaline (above 7.5)": "Alkaline", "Acidic (below 6.5)": "Acidic",
        "Sufficient (81—100%)": "Sufficient", "Deficient (0—50%)": "Deficient",
        "Sufficient (86—100%)": "Sufficient", "Deficient (0—60%)": "Deficient",
        "Low (< 28°C — Too cool for summer crops)": "Low", "Medium (28—35°C — Ideal for warm-season crops)": "Medium", "High (> 35°C — Heat stress risk)": "High",
        "Low (< 10°C — Too cold for most crops)": "Low", "Medium (10—20°C — Ideal for rabi crops)": "Medium", "High (> 20°C — May hinder wheat filling)": "High",
        "Low (< 22°C — Poor germination)": "Low", "Medium (22—30°C — Ideal for kharif crops)": "Medium", "High (> 30°C — Fungal stress risk)": "High",
        "High (1000—1500 mm — Ideal rainfed range)": "High", "Medium (500—1000 mm — May need irrigation)": "Medium", "Low (< 500 mm — Highly insufficient)": "Low"
    }
    normalized = {k.strip(): value_map.get(v.strip(), v.strip()) for k, v in d.items()}
    print("✅ Normalized Input:", normalized)
    return normalized

def evaluate_all_crops(d):
    if "Rainfall overall" in d:
        d["Rainfall"] = d.pop("Rainfall overall")
    results = {}

    # Sugarcane
    cnt = sum([
        d['Nitrogen'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['OC'] in ["High", "Medium"],
        d['EC'] == "Non-Saline",
        d['pH'] in ["Neutral", "Alkaline"],
        d['Temperature_Winter'] == "High",
        d['Rainfall'] in ["High", "Medium"]
    ])
    results["Sugarcane"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")

    # Cotton
    cnt = sum([
        d['Phosphorus'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['Zinc'] == "Sufficient",
        d['pH'] in ["Neutral", "Alkaline"],
        d['Temperature_Winter'] == "High",
        d['Rainfall'] in ["High", "Medium"]
    ])
    results["Cotton"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")

    # Soyabean
    cnt = sum([
        d['Phosphorus'] in ["High", "Medium"],
        d['Boron'] == "Sufficient",
        d['Sulphur'] == "Sufficient",
        d['OC'] in ["High", "Medium"],
        d['pH'] in ["Neutral", "Acidic"],
        d['Rainfall'] in ["High", "Medium"]
    ])
    results["Soyabean"] = "Highly Suitable" if cnt >= 5 else (
        "Moderately Suitable" if cnt == 4 else "Not Suitable"
    )

    # Rice
    cnt = sum([
        d['Nitrogen'] in ["High", "Medium"],
        d['Phosphorus'] in ["High", "Medium"],
        d['pH'] in ["Neutral", "Acidic", "Alkaline"],
        d['EC'] == "Non-Saline",
        d['Temperature_Winter'] == "High",
        d['Rainfall'] == "High",
        d['Boron'] == "Sufficient" or d['Copper'] == "Sufficient"
    ])
    results["Rice"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")

    # Jowar
    cnt = sum([
        d['Potassium'] in ["High", "Medium"],
        d['Zinc'] == "Sufficient",
        d['EC'] == "Non-Saline",
        d['pH'] in ["Neutral", "Alkaline"],
        d['Temperature_Winter'] == "High",
        d['Rainfall'] == "Medium"
    ])
    results["Jowar"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")

    # Tur (Pigeon Pea)
    cnt = sum([
        d['Phosphorus'] in ["High", "Medium", "Low"],
        d['OC'] in ["High", "Medium"],
        d['Iron'] == "Sufficient",
        d['pH'] in ["Neutral", "Alkaline", "Acidic"],
        d['Temperature_Winter'] == "High",
        d['Rainfall'] in ["High", "Medium"]
    ])
    results["Tur (Pigeon Pea)"] = "Highly Suitable" if cnt >= 5 else (
        "Moderately Suitable" if cnt == 4 else "Not Suitable"
    )

    # Wheat
    cnt = sum([
        d['Nitrogen'] in ["High", "Medium"],
        d['Phosphorus'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['Zinc'] == "Sufficient",
        d['Iron'] == "Sufficient",
        d['Manganese'] == "Sufficient",
        d['pH'] == "Neutral",
        d['Temperature_Monsoon'] == "Medium",
        d['Rainfall'] in ["High", "Medium"]
    ])
    results["Wheat"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")

    # Groundnut
    cnt = sum([
        d['Phosphorus'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['Boron'] == "Sufficient",
        d['EC'] == "Non-Saline",
        d['pH'] == "Neutral",
        d['Temperature_Winter'] == "High",
        d['Rainfall'] == "Medium"
    ])
    results["Groundnut"] = "Highly Suitable" if cnt >= 6 else (
        "Moderately Suitable" if cnt == 5 else "Not Suitable"
    )

    # Onion
    cnt = sum([
        d['Potassium'] in ["High", "Medium"],
        d['Sulphur'] == "Sufficient",
        d['Zinc'] == "Sufficient",
        d['OC'] in ["High", "Medium"],
        any(t in ["High", "Medium"] for t in [
            d.get('Temperature_Summer', ''),  # Using get in case keys missing
            d.get('Temperature_Winter', ''),
            d.get('Temperature_Monsoon', '')
        ])
    ])
    results["Onion"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt >= 3 else "Not Suitable")

    # Tomato
    cnt = sum([
        d['Nitrogen'] in ["High", "Medium"],
        d['Phosphorus'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['Zinc'] == "Sufficient",
        d['Boron'] == "Sufficient",
        any(t in ["High", "Medium"] for t in [
            d.get('Temperature_Summer', ''),
            d.get('Temperature_Winter', ''),
            d.get('Temperature_Monsoon', '')
        ])
    ])
    results["Tomato"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")

    # Potato
    cnt = sum([
        d['Nitrogen'] in ["High", "Medium"],
        d['Phosphorus'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['EC'] == "Non-Saline",
        d['pH'] in ["Neutral", "Alkaline"],
        d.get('Temperature_Summer', '') in ["High", "Medium"],
        d.get('Temperature_Monsoon', '') in ["High", "Medium"]
    ])
    results["Potato"] = "Highly Suitable" if cnt >= 6 else ("Moderately Suitable" if cnt == 5 else "Not Suitable")

    # Garlic
    cnt = sum([
        d['Nitrogen'] in ["High", "Medium"],
        d['Potassium'] in ["High", "Medium"],
        d['OC'] in ["High", "Medium"],
        d['pH'] in ["Neutral", "Alkaline"],
        d['Zinc'] == "Sufficient",
        d.get('Temperature_Winter', '') in ["High", "Medium"],
        d['Rainfall'] in ["High", "Medium"]
    ])
    results["Garlic"] = "Highly Suitable" if cnt >= 5 else ("Moderately Suitable" if cnt == 4 else "Not Suitable")

    return results

# ---------------------------
# Dynamic Crop Timeline Generation
# ---------------------------

def analyze_soil_for_crop(crop_name, soil_params):
    """Analyze soil conditions and provide recommendations for specific crop"""
    crop_map = {
        'sugarcane': 'Sugarcane',
        'cotton': 'Cotton', 
        'soyabean': 'Soyabean',
        'rice': 'Rice',
        'jowar': 'Jowar',
        'tur': 'Tur (Pigeon Pea)',
        'wheat': 'Wheat',
        'groundnut': 'Groundnut',
        'onion': 'Onion',
        'tomato': 'Tomato',
        'potato': 'Potato',
        'garlic': 'Garlic'
    }
    
    formal_crop_name = crop_map.get(crop_name.lower(), crop_name.title())
    
    # Soil requirements for each crop
    crop_requirements = {
        'Sugarcane': {
            'ideal_conditions': ['High Nitrogen', 'High/Medium Potassium', 'High/Medium OC', 'Non-Saline EC', 'Neutral/Alkaline pH'],
            'critical_factors': ['Nitrogen', 'EC', 'pH'],
            'growth_period': 365,  # days
            'seasons': ['Kharif', 'Rabi']
        },
        'Cotton': {
            'ideal_conditions': ['High/Medium Phosphorus', 'High/Medium Potassium', 'Sufficient Zinc', 'Neutral/Alkaline pH'],
            'critical_factors': ['Phosphorus', 'Zinc', 'pH'],
            'growth_period': 180,
            'seasons': ['Kharif']
        },
        'Soyabean': {
            'ideal_conditions': ['High/Medium Phosphorus', 'Sufficient Boron', 'Sufficient Sulphur', 'Neutral/Acidic pH'],
            'critical_factors': ['Phosphorus', 'Boron', 'pH'],
            'growth_period': 100,
            'seasons': ['Kharif']
        },
        'Rice': {
            'ideal_conditions': ['High/Medium Nitrogen', 'High/Medium Phosphorus', 'Non-Saline EC', 'High Rainfall'],
            'critical_factors': ['Nitrogen', 'EC', 'Rainfall'],
            'growth_period': 120,
            'seasons': ['Kharif', 'Rabi']
        },
        'Jowar': {
            'ideal_conditions': ['High/Medium Potassium', 'Sufficient Zinc', 'Non-Saline EC', 'Neutral/Alkaline pH'],
            'critical_factors': ['Potassium', 'Zinc', 'EC'],
            'growth_period': 110,
            'seasons': ['Kharif', 'Rabi']
        },
        'Tur (Pigeon Pea)': {
            'ideal_conditions': ['High/Medium OC', 'Sufficient Iron', 'Medium Rainfall'],
            'critical_factors': ['OC', 'Iron', 'Rainfall'],
            'growth_period': 150,
            'seasons': ['Kharif']
        },
        'Wheat': {
            'ideal_conditions': ['High/Medium Nitrogen', 'High/Medium Phosphorus', 'Neutral pH', 'Sufficient Zinc'],
            'critical_factors': ['Nitrogen', 'Phosphorus', 'pH', 'Zinc'],
            'growth_period': 120,
            'seasons': ['Rabi']
        },
        'Groundnut': {
            'ideal_conditions': ['High/Medium Phosphorus', 'Sufficient Boron', 'Non-Saline EC', 'Neutral pH'],
            'critical_factors': ['Phosphorus', 'Boron', 'EC'],
            'growth_period': 110,
            'seasons': ['Kharif', 'Rabi']
        },
        'Onion': {
            'ideal_conditions': ['High/Medium Potassium', 'Sufficient Sulphur', 'High/Medium OC'],
            'critical_factors': ['Potassium', 'Sulphur', 'OC'],
            'growth_period': 150,
            'seasons': ['Rabi', 'Summer']
        },
        'Tomato': {
            'ideal_conditions': ['High/Medium NPK', 'Sufficient Zinc', 'Sufficient Boron'],
            'critical_factors': ['Nitrogen', 'Phosphorus', 'Potassium'],
            'growth_period': 120,
            'seasons': ['Rabi', 'Summer']
        },
        'Potato': {
            'ideal_conditions': ['High/Medium NPK', 'Non-Saline EC', 'Neutral/Alkaline pH'],
            'critical_factors': ['Nitrogen', 'EC', 'pH'],
            'growth_period': 90,
            'seasons': ['Rabi']
        },
        'Garlic': {
            'ideal_conditions': ['High/Medium Nitrogen', 'High/Medium Potassium', 'Sufficient Zinc', 'Neutral/Alkaline pH'],
            'critical_factors': ['Nitrogen', 'Potassium', 'pH'],
            'growth_period': 150,
            'seasons': ['Rabi']
        }
    }
    
    crop_info = crop_requirements.get(formal_crop_name, {})
    recommendations = []
    deficiencies = []
    
    # Check critical factors
    for factor in crop_info.get('critical_factors', []):
        if factor in soil_params:
            value = soil_params[factor]
            if formal_crop_name == 'Sugarcane' and factor == 'Nitrogen' and value == 'Low':
                deficiencies.append(f"Low {factor} - Consider nitrogen-rich fertilizers")
            elif formal_crop_name == 'Cotton' and factor == 'Phosphorus' and value == 'Low':
                deficiencies.append(f"Low {factor} - Apply phosphate fertilizers")
            elif factor == 'pH':
                if formal_crop_name in ['Wheat', 'Groundnut'] and value != 'Neutral':
                    deficiencies.append(f"{value} pH - Consider soil pH adjustment")
                elif formal_crop_name == 'Soyabean' and value == 'Alkaline':
                    deficiencies.append(f"{value} pH - Consider acidifying agents")
    
    # General recommendations based on soil analysis
    if soil_params.get('OC') == 'Low':
        recommendations.append("Increase organic matter through compost or FYM")
    if soil_params.get('EC') == 'Saline':
        recommendations.append("Soil salinity management required - consider drainage")
    if soil_params.get('Rainfall') == 'Low':
        recommendations.append("Irrigation system planning essential")
    
    return {
        'crop': formal_crop_name,
        'growth_period': crop_info.get('growth_period', 120),
        'ideal_seasons': crop_info.get('seasons', ['Kharif']),
        'deficiencies': deficiencies,
        'recommendations': recommendations,
        'soil_score': calculate_soil_score(formal_crop_name, soil_params)
    }

def calculate_soil_score(crop_name, soil_params):
    """Calculate a soil suitability score (0-100) for the crop"""
    # This is a simplified scoring system
    score = 50  # Base score
    
    crop_preferences = {
        'Sugarcane': {'Nitrogen': ['High', 'Medium'], 'EC': ['Non-Saline'], 'pH': ['Neutral', 'Alkaline']},
        'Cotton': {'Phosphorus': ['High', 'Medium'], 'pH': ['Neutral', 'Alkaline'], 'Zinc': ['Sufficient']},
        'Soyabean': {'Phosphorus': ['High', 'Medium'], 'pH': ['Neutral', 'Acidic'], 'Boron': ['Sufficient']},
        'Rice': {'Nitrogen': ['High', 'Medium'], 'EC': ['Non-Saline'], 'Rainfall': ['High']},
        'Wheat': {'Nitrogen': ['High', 'Medium'], 'pH': ['Neutral'], 'Zinc': ['Sufficient']},
        'Groundnut': {'Phosphorus': ['High', 'Medium'], 'EC': ['Non-Saline'], 'pH': ['Neutral']},
        'Potato': {'Nitrogen': ['High', 'Medium'], 'EC': ['Non-Saline'], 'pH': ['Neutral', 'Alkaline']},
        'Garlic': {'Nitrogen': ['High', 'Medium'], 'pH': ['Neutral', 'Alkaline'], 'Potassium': ['High', 'Medium']}
    }
    
    preferences = crop_preferences.get(crop_name, {})
    
    for param, preferred_values in preferences.items():
        if param in soil_params:
            if soil_params[param] in preferred_values:
                score += 10
            else:
                score -= 5
    
    return max(0, min(100, score))

def generate_crop_timeline(crop_name, soil_params, crop_evaluations):
    """Generate fully dynamic timeline based on comprehensive soil analysis"""
    
    # Parse soil parameter values for dynamic analysis
    def extract_value(param_string):
        if 'High' in str(param_string):
            return 'High'
        elif 'Medium' in str(param_string):
            return 'Medium'
        elif 'Low' in str(param_string):
            return 'Low'
        elif 'Sufficient' in str(param_string):
            return 'Sufficient'
        elif 'Deficient' in str(param_string):
            return 'Deficient'
        elif 'Non-Saline' in str(param_string):
            return 'Non-Saline'
        elif 'Saline' in str(param_string):
            return 'Saline'
        elif 'Neutral' in str(param_string):
            return 'Neutral'
        elif 'Acidic' in str(param_string):
            return 'Acidic'
        elif 'Alkaline' in str(param_string):
            return 'Alkaline'
        return str(param_string)
    
    # Extract normalized values
    normalized_params = {k: extract_value(v) for k, v in soil_params.items()}
    
    soil_analysis = analyze_soil_for_crop(crop_name, soil_params)
    growth_period = soil_analysis['growth_period']
    soil_score = soil_analysis['soil_score']
    
    # Enhanced base timelines with comprehensive phase management
    base_timelines = {
        'sugarcane': [
            {'name': 'Soil Testing & Analysis', 'category': 'Analysis', 'duration': 3, 'priority': 'critical'},
            {'name': 'Land Preparation & Leveling', 'category': 'Preparation', 'duration': 15, 'priority': 'high'},
            {'name': 'Soil Treatment & Amendment', 'category': 'Treatment', 'duration': 7, 'priority': 'medium'},
            {'name': 'Sett Treatment & Planting', 'category': 'Planting', 'duration': 10, 'priority': 'critical'},
            {'name': 'Irrigation & Early Care', 'category': 'Irrigation', 'duration': 20, 'priority': 'high'},
            {'name': 'Fertilizer Application Program', 'category': 'Fertilization', 'duration': 15, 'priority': 'high'},
            {'name': 'Tillering Phase Management', 'category': 'Growth', 'duration': 60, 'priority': 'medium'},
            {'name': 'Grand Growth Phase', 'category': 'Growth', 'duration': 120, 'priority': 'medium'},
            {'name': 'Maturation Monitoring', 'category': 'Monitoring', 'duration': 90, 'priority': 'medium'},
            {'name': 'Harvesting Operations', 'category': 'Harvest', 'duration': 25, 'priority': 'critical'}
        ],
        'cotton': [
            {'name': 'Soil Analysis & Testing', 'category': 'Analysis', 'duration': 3, 'priority': 'critical'},
            {'name': 'Land Preparation', 'category': 'Preparation', 'duration': 12, 'priority': 'high'},
            {'name': 'Soil Treatment', 'category': 'Treatment', 'duration': 5, 'priority': 'medium'},
            {'name': 'Seed Treatment & Sowing', 'category': 'Planting', 'duration': 7, 'priority': 'critical'},
            {'name': 'Germination & Thinning', 'category': 'Growth', 'duration': 20, 'priority': 'high'},
            {'name': 'Vegetative Growth Management', 'category': 'Growth', 'duration': 45, 'priority': 'medium'},
            {'name': 'Flowering & Boll Formation', 'category': 'Flowering', 'duration': 50, 'priority': 'high'},
            {'name': 'Boll Development', 'category': 'Development', 'duration': 35, 'priority': 'medium'},
            {'name': 'Maturation & Picking', 'category': 'Harvest', 'duration': 30, 'priority': 'critical'}
        ],
        'rice': [
            {'name': 'Nursery Preparation', 'category': 'Preparation', 'duration': 10, 'priority': 'high'},
            {'name': 'Field Preparation & Puddling', 'category': 'Preparation', 'duration': 12, 'priority': 'high'},
            {'name': 'Transplanting', 'category': 'Planting', 'duration': 3, 'priority': 'critical'},
            {'name': 'Establishment Phase', 'category': 'Growth', 'duration': 15, 'priority': 'high'},
            {'name': 'Tillering Stage', 'category': 'Growth', 'duration': 30, 'priority': 'medium'},
            {'name': 'Panicle Initiation', 'category': 'Flowering', 'duration': 25, 'priority': 'high'},
            {'name': 'Grain Filling', 'category': 'Development', 'duration': 30, 'priority': 'medium'},
            {'name': 'Maturity & Harvesting', 'category': 'Harvest', 'duration': 15, 'priority': 'critical'}
        ],
        'wheat': [
            {'name': 'Field Preparation', 'category': 'Preparation', 'duration': 10, 'priority': 'high'},
            {'name': 'Seed Treatment & Sowing', 'category': 'Planting', 'duration': 5, 'priority': 'critical'},
            {'name': 'Germination', 'category': 'Growth', 'duration': 15, 'priority': 'high'},
            {'name': 'Tillering Phase', 'category': 'Growth', 'duration': 40, 'priority': 'medium'},
            {'name': 'Jointing & Booting', 'category': 'Growth', 'duration': 30, 'priority': 'medium'},
            {'name': 'Flowering & Grain Formation', 'category': 'Flowering', 'duration': 25, 'priority': 'high'},
            {'name': 'Grain Filling & Maturity', 'category': 'Development', 'duration': 25, 'priority': 'medium'},
            {'name': 'Harvesting', 'category': 'Harvest', 'duration': 10, 'priority': 'critical'}
        ],
        'soyabean': [
            {'name': 'Field Preparation', 'category': 'Preparation', 'duration': 8, 'priority': 'high'},
            {'name': 'Seed Treatment & Sowing', 'category': 'Planting', 'duration': 5, 'priority': 'critical'},
            {'name': 'Germination & Early Growth', 'category': 'Growth', 'duration': 15, 'priority': 'high'},
            {'name': 'Vegetative Growth', 'category': 'Growth', 'duration': 30, 'priority': 'medium'},
            {'name': 'Flowering & Pod Formation', 'category': 'Flowering', 'duration': 25, 'priority': 'high'},
            {'name': 'Pod Filling', 'category': 'Development', 'duration': 20, 'priority': 'medium'},
            {'name': 'Maturation & Harvesting', 'category': 'Harvest', 'duration': 12, 'priority': 'critical'}
        ],
        'jowar': [
            {'name': 'Land Preparation', 'category': 'Preparation', 'duration': 8, 'priority': 'high'},
            {'name': 'Sowing & Germination', 'category': 'Planting', 'duration': 10, 'priority': 'critical'},
            {'name': 'Vegetative Growth', 'category': 'Growth', 'duration': 35, 'priority': 'medium'},
            {'name': 'Flowering Stage', 'category': 'Flowering', 'duration': 20, 'priority': 'high'},
            {'name': 'Grain Filling', 'category': 'Development', 'duration': 25, 'priority': 'medium'},
            {'name': 'Maturity & Harvesting', 'category': 'Harvest', 'duration': 12, 'priority': 'critical'}
        ],
        'tur': [
            {'name': 'Field Preparation', 'category': 'Preparation', 'duration': 10, 'priority': 'high'},
            {'name': 'Seed Treatment & Sowing', 'category': 'Planting', 'duration': 7, 'priority': 'critical'},
            {'name': 'Germination & Early Growth', 'category': 'Growth', 'duration': 20, 'priority': 'high'},
            {'name': 'Vegetative Growth', 'category': 'Growth', 'duration': 50, 'priority': 'medium'},
            {'name': 'Flowering & Pod Development', 'category': 'Flowering', 'duration': 40, 'priority': 'high'},
            {'name': 'Pod Maturation', 'category': 'Development', 'duration': 30, 'priority': 'medium'},
            {'name': 'Harvesting', 'category': 'Harvest', 'duration': 15, 'priority': 'critical'}
        ],
        'groundnut': [
            {'name': 'Field Preparation', 'category': 'Preparation', 'duration': 8, 'priority': 'high'},
            {'name': 'Seed Treatment & Sowing', 'category': 'Planting', 'duration': 5, 'priority': 'critical'},
            {'name': 'Germination & Early Growth', 'category': 'Growth', 'duration': 15, 'priority': 'high'},
            {'name': 'Pegging & Penetration', 'category': 'Growth', 'duration': 25, 'priority': 'medium'},
            {'name': 'Pod Development', 'category': 'Development', 'duration': 35, 'priority': 'high'},
            {'name': 'Pod Filling & Maturation', 'category': 'Development', 'duration': 25, 'priority': 'medium'},
            {'name': 'Harvesting & Drying', 'category': 'Harvest', 'duration': 12, 'priority': 'critical'}
        ],
        'onion': [
            {'name': 'Nursery Preparation', 'category': 'Preparation', 'duration': 15, 'priority': 'high'},
            {'name': 'Nursery Management', 'category': 'Management', 'duration': 25, 'priority': 'medium'},
            {'name': 'Transplanting', 'category': 'Planting', 'duration': 7, 'priority': 'critical'},
            {'name': 'Establishment Phase', 'category': 'Growth', 'duration': 20, 'priority': 'high'},
            {'name': 'Bulb Initiation', 'category': 'Growth', 'duration': 30, 'priority': 'medium'},
            {'name': 'Bulb Development', 'category': 'Development', 'duration': 40, 'priority': 'high'},
            {'name': 'Maturation & Harvesting', 'category': 'Harvest', 'duration': 15, 'priority': 'critical'}
        ],
        'tomato': [
            {'name': 'Nursery Preparation', 'category': 'Preparation', 'duration': 10, 'priority': 'high'},
            {'name': 'Nursery Management', 'category': 'Management', 'duration': 20, 'priority': 'medium'},
            {'name': 'Transplanting', 'category': 'Planting', 'duration': 5, 'priority': 'critical'},
            {'name': 'Establishment & Growth', 'category': 'Growth', 'duration': 25, 'priority': 'high'},
            {'name': 'Flowering & Fruit Setting', 'category': 'Flowering', 'duration': 30, 'priority': 'high'},
            {'name': 'Fruit Development', 'category': 'Development', 'duration': 35, 'priority': 'medium'},
            {'name': 'Harvesting (Multiple Picks)', 'category': 'Harvest', 'duration': 30, 'priority': 'critical'}
        ],
        'potato': [
            {'name': 'Field Preparation', 'category': 'Preparation', 'duration': 10, 'priority': 'high'},
            {'name': 'Seed Treatment & Planting', 'category': 'Planting', 'duration': 7, 'priority': 'critical'},
            {'name': 'Germination & Emergence', 'category': 'Growth', 'duration': 15, 'priority': 'high'},
            {'name': 'Vegetative Growth', 'category': 'Growth', 'duration': 30, 'priority': 'medium'},
            {'name': 'Tuber Initiation', 'category': 'Development', 'duration': 20, 'priority': 'high'},
            {'name': 'Tuber Bulking', 'category': 'Development', 'duration': 35, 'priority': 'medium'},
            {'name': 'Maturation & Harvesting', 'category': 'Harvest', 'duration': 15, 'priority': 'critical'}
        ],
        'garlic': [
            {'name': 'Field Preparation', 'category': 'Preparation', 'duration': 8, 'priority': 'high'},
            {'name': 'Clove Planting', 'category': 'Planting', 'duration': 5, 'priority': 'critical'},
            {'name': 'Germination & Early Growth', 'category': 'Growth', 'duration': 20, 'priority': 'high'},
            {'name': 'Vegetative Growth', 'category': 'Growth', 'duration': 40, 'priority': 'medium'},
            {'name': 'Bulb Formation', 'category': 'Development', 'duration': 45, 'priority': 'high'},
            {'name': 'Bulb Maturation', 'category': 'Development', 'duration': 25, 'priority': 'medium'},
            {'name': 'Harvesting & Curing', 'category': 'Harvest', 'duration': 15, 'priority': 'critical'}
        ]
    }
    
    # Get base timeline
    timeline_phases = base_timelines.get(crop_name.lower(), base_timelines['cotton'])
    
    # Apply comprehensive dynamic adjustments
    adjusted_timeline = []
    additional_phases = []
    
    # Check for critical soil issues that require additional phases
    if normalized_params.get('pH') in ['Acidic', 'Alkaline']:
        if normalized_params.get('pH') == 'Acidic':
            additional_phases.append({
                'name': '🧪 Lime Application (pH Correction)',
                'category': 'Treatment',
                'duration': 14,
                'priority': 'critical',
                'description': 'Apply agricultural lime to neutralize soil acidity'
            })
        else:
            additional_phases.append({
                'name': '🧪 Gypsum Application (pH Correction)',
                'category': 'Treatment', 
                'duration': 12,
                'priority': 'critical',
                'description': 'Apply gypsum to reduce soil alkalinity'
            })
    
    if normalized_params.get('EC') == 'Saline':
        additional_phases.append({
            'name': '💧 Salinity Leaching Treatment',
            'category': 'Treatment',
            'duration': 21,
            'priority': 'critical',
            'description': 'Leach excess salts through controlled irrigation'
        })
    
    if normalized_params.get('OC') == 'Low':
        additional_phases.append({
            'name': '🌱 Organic Matter Enhancement',
            'category': 'Treatment',
            'duration': 10,
            'priority': 'high',
            'description': 'Apply farmyard manure and compost'
        })
    
    # Micronutrient deficiency treatments
    deficient_micronutrients = []
    if normalized_params.get('Zinc') == 'Deficient':
        deficient_micronutrients.append('Zinc Sulfate')
    if normalized_params.get('Boron') == 'Deficient':
        deficient_micronutrients.append('Borax')
    if normalized_params.get('Iron') == 'Deficient':
        deficient_micronutrients.append('Iron Chelate')
    if normalized_params.get('Manganese') == 'Deficient':
        deficient_micronutrients.append('Manganese Sulfate')
    
    if deficient_micronutrients:
        additional_phases.append({
            'name': f'⚗️ Micronutrient Application ({", ".join(deficient_micronutrients)})',
            'category': 'Treatment',
            'duration': 5,
            'priority': 'medium',
            'description': f'Apply {", ".join(deficient_micronutrients)} to correct deficiencies'
        })
    
    # Process each phase with dynamic adjustments
    for phase in timeline_phases:
        adjusted_phase = phase.copy()
        base_duration = phase['duration']
        multiplier = 1.0
        modifications = []
        
        # Category-specific adjustments based on soil conditions
        category = phase['category']
        
        if category == 'Preparation':
            # pH impact on preparation
            if normalized_params.get('pH') in ['Acidic', 'Alkaline']:
                multiplier *= 1.3
                modifications.append('Extended for pH management')
            
            # Salinity impact
            if normalized_params.get('EC') == 'Saline':
                multiplier *= 1.4
                modifications.append('Extended for salinity management')
            
            # Organic carbon impact
            if normalized_params.get('OC') == 'Low':
                multiplier *= 1.2
                modifications.append('Extended for organic matter incorporation')
        
        elif category in ['Growth', 'Development']:
            # NPK impact on growth phases
            npk_deficiencies = 0
            if normalized_params.get('Nitrogen') == 'Low':
                npk_deficiencies += 1
            if normalized_params.get('Phosphorus') == 'Low':
                npk_deficiencies += 1
            if normalized_params.get('Potassium') == 'Low':
                npk_deficiencies += 1
            
            if npk_deficiencies > 0:
                multiplier *= (1.0 + (npk_deficiencies * 0.15))
                modifications.append(f'Extended due to {npk_deficiencies} major nutrient deficiencies')
            
            # Micronutrient impact
            if len(deficient_micronutrients) > 2:
                multiplier *= 1.1
                modifications.append('Extended for micronutrient management')
        
        elif category == 'Fertilization':
            # Nutrient deficiency impact on fertilization
            if normalized_params.get('Nitrogen') == 'Low':
                multiplier *= 1.3
                modifications.append('Extended nitrogen application program')
            if normalized_params.get('Phosphorus') == 'Low':
                multiplier *= 1.2
                modifications.append('Extended phosphorus application')
        
        elif category in ['Irrigation', 'Management']:
            # Salinity and rainfall impact
            if normalized_params.get('EC') == 'Saline':
                multiplier *= 1.5
                modifications.append('Frequent leaching irrigations required')
            if normalized_params.get('Rainfall') == 'Low':
                multiplier *= 1.4
                modifications.append('Intensive irrigation schedule')
        
        # Apply multiplier and round to nearest day
        adjusted_phase['duration'] = max(1, int(base_duration * multiplier))
        
        # Add modifications to phase
        if modifications:
            adjusted_phase['modifications'] = modifications
            # Add contextual information to phase name
            if len(modifications) <= 2:
                adjusted_phase['name'] += f' ({", ".join(modifications)})'
        
        # Add dynamic icons based on priority and modifications
        if len(modifications) > 0:
            if phase['priority'] == 'critical':
                adjusted_phase['name'] = '🚨 ' + adjusted_phase['name']
            elif multiplier > 1.3:
                adjusted_phase['name'] = '⚠️ ' + adjusted_phase['name']
            elif multiplier > 1.1:
                adjusted_phase['name'] = '📋 ' + adjusted_phase['name']
        else:
            if phase['priority'] == 'critical':
                adjusted_phase['name'] = '✅ ' + adjusted_phase['name']
            elif phase['priority'] == 'high':
                adjusted_phase['name'] = '🔶 ' + adjusted_phase['name']
            else:
                adjusted_phase['name'] = '📊 ' + adjusted_phase['name']
        
        adjusted_timeline.append(adjusted_phase)
    
    # Insert additional treatment phases after first phase (usually soil testing/preparation)
    if additional_phases:
        if len(adjusted_timeline) > 0:
            # Insert after first phase
            final_timeline = [adjusted_timeline[0]] + additional_phases + adjusted_timeline[1:]
        else:
            final_timeline = additional_phases + adjusted_timeline
    else:
        final_timeline = adjusted_timeline
    
    # Convert to Gantt chart format with dates
    timeline = []
    current_date = datetime(2025, 2, 1)  # Start date
    
    for i, phase in enumerate(final_timeline):
        start_date = current_date
        end_date = current_date + timedelta(days=phase['duration'])
        
        timeline.append({
            'id': str(i + 1),
            'task_name': phase['name'],
            'category': phase['category'],
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'duration': phase['duration'],
            'priority': phase.get('priority', 'medium'),
            'modifications': phase.get('modifications', []),
            'description': phase.get('description', ''),
            'dependencies': str(i) if i > 0 else None
        })
        
        current_date = end_date + timedelta(days=1)
    
    return timeline

def apply_comprehensive_soil_adjustments(timeline_phases, soil_params, crop_name):
    """Apply comprehensive dynamic adjustments based on all soil parameters"""
    
    # Parse soil parameter values
    def extract_value(param_string):
        if 'High' in param_string:
            return 'High'
        elif 'Medium' in param_string:
            return 'Medium'
        elif 'Low' in param_string:
            return 'Low'
        elif 'Sufficient' in param_string:
            return 'Sufficient'
        elif 'Deficient' in param_string:
            return 'Deficient'
        elif 'Non-Saline' in param_string:
            return 'Non-Saline'
        elif 'Saline' in param_string:
            return 'Saline'
        elif 'Neutral' in param_string:
            return 'Neutral'
        elif 'Acidic' in param_string:
            return 'Acidic'
        elif 'Alkaline' in param_string:
            return 'Alkaline'
        return param_string
    
    # Extract normalized values
    normalized_params = {k: extract_value(v) for k, v in soil_params.items()}
    
    adjusted_timeline = []
    additional_phases = []
    
    # Check for critical soil issues that require additional phases
    if normalized_params.get('pH') in ['Acidic', 'Alkaline']:
        if normalized_params.get('pH') == 'Acidic':
            additional_phases.append({
                'name': '🧪 Lime Application (pH Correction)',
                'category': 'Treatment',
                'duration': 14,
                'priority': 'critical',
                'description': 'Apply agricultural lime to neutralize soil acidity'
            })
        else:
            additional_phases.append({
                'name': '🧪 Gypsum Application (pH Correction)',
                'category': 'Treatment', 
                'duration': 12,
                'priority': 'critical',
                'description': 'Apply gypsum to reduce soil alkalinity'
            })
    
    if normalized_params.get('EC') == 'Saline':
        additional_phases.append({
            'name': '💧 Salinity Leaching Treatment',
            'category': 'Treatment',
            'duration': 21,
            'priority': 'critical',
            'description': 'Leach excess salts through controlled irrigation'
        })
    
    if normalized_params.get('OC') == 'Low':
        additional_phases.append({
            'name': '🌱 Organic Matter Enhancement',
            'category': 'Treatment',
            'duration': 10,
            'priority': 'high',
            'description': 'Apply farmyard manure and compost'
        })
    
    # Micronutrient deficiency treatments
    deficient_micronutrients = []
    if normalized_params.get('Zinc') == 'Deficient':
        deficient_micronutrients.append('Zinc Sulfate')
    if normalized_params.get('Boron') == 'Deficient':
        deficient_micronutrients.append('Borax')
    if normalized_params.get('Iron') == 'Deficient':
        deficient_micronutrients.append('Iron Chelate')
    if normalized_params.get('Manganese') == 'Deficient':
        deficient_micronutrients.append('Manganese Sulfate')
    
    if deficient_micronutrients:
        additional_phases.append({
            'name': f'⚗️ Micronutrient Application ({', '.join(deficient_micronutrients)})',
            'category': 'Treatment',
            'duration': 5,
            'priority': 'medium',
            'description': f'Apply {', '.join(deficient_micronutrients)} to correct deficiencies'
        })
    
    # Process each phase with dynamic adjustments
    for phase in timeline_phases:
        adjusted_phase = phase.copy()
        base_duration = phase['duration']
        multiplier = 1.0
        modifications = []
        
        # Category-specific adjustments based on soil conditions
        category = phase['category']
        
        if category == 'Preparation':
            # pH impact on preparation
            if normalized_params.get('pH') in ['Acidic', 'Alkaline']:
                multiplier *= 1.3
                modifications.append('Extended for pH management')
            
            # Salinity impact
            if normalized_params.get('EC') == 'Saline':
                multiplier *= 1.4
                modifications.append('Extended for salinity management')
            
            # Organic carbon impact
            if normalized_params.get('OC') == 'Low':
                multiplier *= 1.2
                modifications.append('Extended for organic matter incorporation')
        
        elif category in ['Growth', 'Development']:
            # NPK impact on growth phases
            npk_deficiencies = 0
            if normalized_params.get('Nitrogen') == 'Low':
                npk_deficiencies += 1
            if normalized_params.get('Phosphorus') == 'Low':
                npk_deficiencies += 1
            if normalized_params.get('Potassium') == 'Low':
                npk_deficiencies += 1
            
            if npk_deficiencies > 0:
                multiplier *= (1.0 + (npk_deficiencies * 0.15))
                modifications.append(f'Extended due to {npk_deficiencies} major nutrient deficiencies')
            
            # Micronutrient impact
            if len(deficient_micronutrients) > 2:
                multiplier *= 1.1
                modifications.append('Extended for micronutrient management')
        
        elif category == 'Fertilization':
            # Nutrient deficiency impact on fertilization
            if normalized_params.get('Nitrogen') == 'Low':
                multiplier *= 1.3
                modifications.append('Extended nitrogen application program')
            if normalized_params.get('Phosphorus') == 'Low':
                multiplier *= 1.2
                modifications.append('Extended phosphorus application')
        
        elif category == 'Irrigation':
            # Salinity and rainfall impact
            if normalized_params.get('EC') == 'Saline':
                multiplier *= 1.5
                modifications.append('Frequent leaching irrigations required')
            if normalized_params.get('Rainfall') == 'Low':
                multiplier *= 1.4
                modifications.append('Intensive irrigation schedule')
        
        # Apply multiplier and round to nearest day
        adjusted_phase['duration'] = max(1, int(base_duration * multiplier))
        
        # Add modifications to phase name if any
        if modifications:
            adjusted_phase['modifications'] = modifications
            adjusted_phase['name'] += f" ({', '.join(modifications[:2])})"
        
        # Add soil-specific icons based on priority and modifications
        if len(modifications) > 0:
            if phase['priority'] == 'critical':
                adjusted_phase['name'] = '🚨 ' + adjusted_phase['name']
            elif multiplier > 1.3:
                adjusted_phase['name'] = '⚠️ ' + adjusted_phase['name']
            elif multiplier > 1.1:
                adjusted_phase['name'] = '📋 ' + adjusted_phase['name']
        else:
            if phase['priority'] == 'critical':
                adjusted_phase['name'] = '✅ ' + adjusted_phase['name']
            elif phase['priority'] == 'high':
                adjusted_phase['name'] = '🔶 ' + adjusted_phase['name']
            else:
                adjusted_phase['name'] = '📊 ' + adjusted_phase['name']
        
        adjusted_timeline.append(adjusted_phase)
    
    # Insert additional treatment phases after soil testing (if first phase exists)
    if additional_phases:
        if len(adjusted_timeline) > 0:
            # Insert after first phase (usually soil testing/preparation)
            final_timeline = [adjusted_timeline[0]] + additional_phases + adjusted_timeline[1:]
        else:
            final_timeline = additional_phases + adjusted_timeline
    else:
        final_timeline = adjusted_timeline
    
    return final_timeline

def convert_to_gantt_format(timeline_phases, crop_name):
    """Convert timeline phases to Gantt chart format with dates"""
    
    timeline = []
    current_date = datetime(2025, 2, 1)  # Start date
    
    for i, phase in enumerate(timeline_phases):
        start_date = current_date
        end_date = current_date + timedelta(days=phase['duration'])
        
        timeline.append({
            'id': str(i + 1),
            'task_name': phase['name'],
            'category': phase['category'],
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'duration': phase['duration'],
            'priority': phase.get('priority', 'medium'),
            'modifications': phase.get('modifications', []),
            'description': phase.get('description', ''),
            'dependencies': str(i) if i > 0 else None
        })
        
        current_date = end_date + timedelta(days=1)
    
    return timeline

# ---------------------------
# Fetch Market Prices from External API
# ---------------------------

def fetch_market_prices(state, mandi, crop):
    url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    params = {
        "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
        "format": "json",
        "filters[state]": state,
        "filters[market]": mandi,
        "filters[commodity]": crop,
        "limit": 500
    }
    resp = requests.get(url, params=params)
    if resp.status_code != 200:
        return {"error": "Failed to fetch data"}

    data = resp.json().get("records", [])
    history = []
    today = datetime.today()
    seven_days_ago = today - timedelta(days=7)

    for row in data:
        try:
            date_obj = datetime.strptime(row["arrival_date"], "%d/%m/%Y")
            if date_obj >= seven_days_ago:
                price = float(row["modal_price"])
                history.append({"date": row["arrival_date"], "modal_price": price})
        except Exception:
            continue

    history.sort(key=lambda x: datetime.strptime(x["date"], "%d/%m/%Y"))

    if not history:
        return {"error": "No data found for given filters in last 7 days"}

    latest = history[-1]
    avg_7d = sum(h["modal_price"] for h in history) / len(history)
    change = ((latest["modal_price"] - history[0]["modal_price"]) / history[0]["modal_price"]) * 100

    return {
        "crop": crop,
        "mandi": mandi,
        "state": state,
        "history": history,
        "latest": {
            "modal_price": latest["modal_price"],
            "change_pct": round(change, 2),
            "avg_7d": round(avg_7d, 2)
        }
    }

# ---------------------------
# Feedback Storage Functions
# ---------------------------

FEEDBACK_FILE = ROOT / "feedback.json"

def save_feedback_to_json(feedback_data):
    if FEEDBACK_FILE.exists():
        with open(FEEDBACK_FILE, "r", encoding="utf-8") as f:
            try:
                feedback_list = json.load(f)
            except json.JSONDecodeError:
                feedback_list = []
    else:
        feedback_list = []

    feedback_data["timestamp"] = datetime.utcnow().isoformat() + "Z"
    feedback_list.append(feedback_data)

    with open(FEEDBACK_FILE, "w", encoding="utf-8") as f:
        json.dump(feedback_list, f, indent=2, ensure_ascii=False)

# ---------------------------
# Routes for Site
# ---------------------------

@app.route('/')
def home():
    """Redirect to login if not logged in, otherwise show main page"""
    if is_user_logged_in():
        return render_template('main.html')
    else:
        return redirect(url_for('login'))

@app.route('/home-landing')
def home_landing():
    """Landing page with voice navigation"""
    return render_template('home.html')

@app.route('/api/voice-config')
def voice_config():
    """API endpoint to provide voice navigation configuration"""
    return jsonify({
        'gemini_api_key': GEMINI_API_KEY,
        'supported_languages': {
            'en-US': 'English',
            'hi-IN': 'हिंदी (Hindi)', 
            'mr-IN': 'मराठी (Marathi)'
        }
    })

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Handle login page and authentication"""
    if request.method == 'POST':
        country_code = request.form.get('country_code', '+91')
        phone = request.form.get('phone', '').strip()

        # Validate phone number
        if not phone:
            flash('Phone number is required', 'error')
            return render_template('login.html')

        if not validate_phone_number(phone, country_code):
            flash('Please enter a valid phone number', 'error')
            return render_template('login.html')

        # In a real app, you would validate against a database
        # For now, we'll accept any valid phone number
        full_phone = f"{country_code}{phone}"

        # Store user info in session
        session['logged_in'] = True
        session['phone'] = full_phone
        session['country_code'] = country_code
        session['login_time'] = datetime.now().isoformat()

        flash('Login successful! Welcome to Farm Ops.', 'success')
        return redirect(url_for('main_dashboard'))

    # Allow access to login page even when logged in
    # Users can logout first or switch accounts
    current_user = None
    if is_user_logged_in():
        current_user = session.get('phone', 'Unknown')

    return render_template('login.html', current_user=current_user)

@app.route('/main')
@require_login
def main_dashboard():
    """Main dashboard - requires login"""
    return render_template('main.html')

@app.route('/test-translation')
def test_translation():
    """Test route for translation system"""
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Translation Test</title>
        <script src="static/global-translations.js"></script>
    </head>
    <body>
        <h1 data-translate="nav.home">HOME</h1>
        <p data-translate="hero.title">Crop Intelligence Advisor</p>
        <p data-translate="features.location.title">Location Based Crop Suggestion</p>
        
        <select onchange="testTranslation(this.value)">
            <option value="en">English</option>
            <option value="hi">Hindi</option>
        </select>
        
        <button onclick="checkSystem()">Check System</button>
        
        <script>
            function testTranslation(lang) {
                console.log('Testing translation for:', lang);
                
                if (typeof GlobalTranslationSystem !== 'undefined') {
                    const translationSystem = new GlobalTranslationSystem();
                    translationSystem.changeLanguage(lang);
                    console.log('Translation applied');
                } else {
                    console.error('GlobalTranslationSystem not found');
                }
            }
            
            function checkSystem() {
                console.log('=== SYSTEM CHECK ===');
                console.log('GlobalTranslationSystem:', typeof GlobalTranslationSystem);
                console.log('GLOBAL_TRANSLATIONS:', typeof GLOBAL_TRANSLATIONS);
                console.log('Available languages:', GLOBAL_TRANSLATIONS ? Object.keys(GLOBAL_TRANSLATIONS) : 'None');
                
                // Test specific translations
                if (GLOBAL_TRANSLATIONS && GLOBAL_TRANSLATIONS.hi) {
                    console.log('Hindi nav.home:', GLOBAL_TRANSLATIONS.hi['nav.home']);
                    console.log('Hindi hero.title:', GLOBAL_TRANSLATIONS.hi['hero.title']);
                }
            }
            
            // Initialize on load
            document.addEventListener('DOMContentLoaded', function() {
                console.log('Page loaded');
                checkSystem();
                
                if (typeof GlobalTranslationSystem !== 'undefined') {
                    const translationSystem = new GlobalTranslationSystem();
                    translationSystem.initialize();
                    console.log('Translation system initialized');
                }
            });
        </script>
    </body>
    </html>
    '''

@app.route('/logout')
def logout():
    """Log out the user"""
    session.clear()
    flash('You have been logged out successfully.', 'success')
    return redirect(url_for('login'))

@app.route('/features')
@require_login
def features():
    return render_template('features.html')

@app.route('/yieldwise')
@require_login
def yieldwise():
    """YieldWise - Profit Loss Calculator for farming operations"""
    return render_template('yieldwise.html')

@app.route('/api/yieldwise/market-price/<crop>')
@require_login
def get_yieldwise_market_price(crop):
    """Get current market price for specific crop for YieldWise calculator"""
    try:
        # Get user's location from session if available
        state = session.get('user_state', 'Maharashtra')
        district = session.get('user_district', 'Pune')
        
        # Get enhanced market price data
        price_data = get_enhanced_simulated_price(crop, state, district)
        
        # Add additional market insights
        crop_insights = get_crop_market_insights(crop, price_data['price'])
        
        return jsonify({
            'success': True,
            'crop': crop,
            'price': price_data['price'],
            'market': price_data['market'],
            'date': price_data['date'],
            'insights': crop_insights,
            'location': f'{district}, {state}',
            'price_trend': get_price_trend(crop),
            'confidence': 'high' if 'simulation' not in price_data.get('source_type', '') else 'medium'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'price': 2500,  # Default fallback
            'confidence': 'low'
        })

@app.route('/api/yieldwise/profitability-analysis')
@require_login
def analyze_crop_profitability():
    """Analyze profitability of different crops based on location and market conditions"""
    try:
        state = request.args.get('state', 'Maharashtra')
        district = request.args.get('district', 'Pune')
        farm_size = float(request.args.get('farm_size', 5.0))
        
        # Analyze profitability for major crops
        crops_to_analyze = ['rice', 'wheat', 'cotton', 'sugarcane', 'soybean', 'groundnut', 'tomato', 'onion']
        profitability_data = []
        
        for crop in crops_to_analyze:
            analysis = analyze_single_crop_profitability(crop, state, district, farm_size)
            profitability_data.append(analysis)
        
        # Sort by profit potential
        profitability_data.sort(key=lambda x: x['estimated_profit'], reverse=True)
        
        return jsonify({
            'success': True,
            'location': f'{district}, {state}',
            'farm_size': farm_size,
            'analysis_date': datetime.now().strftime('%Y-%m-%d'),
            'crops': profitability_data[:6],  # Top 6 most profitable
            'market_conditions': get_current_market_conditions()
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/yieldwise/recommendations')
@require_login
def get_farming_recommendations():
    """Get personalized farming recommendations based on profit analysis"""
    try:
        # Get parameters from request
        crop = request.args.get('crop', '')
        profit = float(request.args.get('profit', 0))
        roi = float(request.args.get('roi', 0))
        farm_area = float(request.args.get('farm_area', 5))
        total_cost = float(request.args.get('total_cost', 100000))
        
        recommendations = generate_smart_recommendations({
            'crop': crop,
            'profit': profit,
            'roi': roi,
            'farm_area': farm_area,
            'total_cost': total_cost
        })
        
        return jsonify({
            'success': True,
            'recommendations': recommendations,
            'generated_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/yieldwise/cost-benchmarks/<crop>')
@require_login
def get_cost_benchmarks(crop):
    """Get cost benchmarks and industry standards for specific crop"""
    try:
        benchmarks = get_crop_cost_benchmarks(crop)
        return jsonify({
            'success': True,
            'crop': crop,
            'benchmarks': benchmarks,
            'last_updated': datetime.now().strftime('%Y-%m-%d')
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/get-locations')
@require_login
def get_locations():
    """Get hierarchical location data from Excel database"""
    try:
        # Read Excel file
        excel_file = Path(ROOT) / "cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        
        # Clean column names
        df.columns = df.columns.str.strip()
        
        # Get unique states
        states = df['STATE'].dropna().unique().tolist()
        
        return jsonify({
            'success': True,
            'states': sorted([s for s in states if pd.notna(s)])
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/get-districts/<state>')
@require_login
def get_districts(state):
    """Get districts for a specific state"""
    try:
        excel_file = Path(ROOT) / "cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        df.columns = df.columns.str.strip()
        
        districts = df[df['STATE'] == state]['DISTRICT NAME'].dropna().unique().tolist()
        
        return jsonify({
            'success': True,
            'districts': sorted([d for d in districts if pd.notna(d)])
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/get-blocks/<state>/<district>')
@require_login
def get_blocks(state, district):
    """Get blocks for a specific state and district"""
    try:
        excel_file = Path(ROOT) / "cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        df.columns = df.columns.str.strip()
        
        blocks = df[(df['STATE'] == state) & (df['DISTRICT NAME'] == district)]['BLOCK NAME'].dropna().unique().tolist()
        
        return jsonify({
            'success': True,
            'blocks': sorted([b for b in blocks if pd.notna(b)])
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/get-villages/<state>/<district>/<block>')
@require_login
def get_villages(state, district, block):
    """Get villages for a specific state, district, and block"""
    try:
        excel_file = Path(ROOT) / "cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        df.columns = df.columns.str.strip()
        
        villages = df[
            (df['STATE'] == state) & 
            (df['DISTRICT NAME'] == district) & 
            (df['BLOCK NAME'] == block)
        ]['VILLAGE NAME'].dropna().unique().tolist()
        
        return jsonify({
            'success': True,
            'villages': sorted([v for v in villages if pd.notna(v)])
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/get-market-price/<state>/<district>/<crop>')
@require_login
def get_market_price(state, district, crop):
    """Get the best available market price for crop in specific location"""
    try:
        # Get the best available price from multiple sources
        price_data = get_best_market_price(state, district, crop)
        
        if price_data.get('success'):
            return jsonify({
                'success': True,
                'price': price_data['price'],
                'source': price_data['source'],
                'market': price_data['market'],
                'date': price_data['date'],
                'confidence': price_data.get('confidence', 'medium'),
                'message': f"Best available price from {price_data['source']} source"
            })
        else:
            return jsonify({
                'success': False,
                'error': price_data.get('error', 'Unknown error'),
                'price': price_data.get('price', 2500),
                'source': 'fallback',
                'market': 'Default Market',
                'date': datetime.now().strftime('%Y-%m-%d'),
                'confidence': 'low'
            })
    
    except Exception as e:
        return jsonify({
            'success': False, 
            'error': str(e),
            'price': 2500,
            'source': 'error_fallback',
            'market': 'Default Market',
            'date': datetime.now().strftime('%Y-%m-%d'),
            'confidence': 'low'
        })

@app.route('/api/get-multiple-prices/<state>/<district>')
@require_login
def get_multiple_prices(state, district):
    """Get market prices for multiple crops at once"""
    try:
        crops = ['rice', 'wheat', 'cotton', 'sugarcane', 'soybean', 'groundnut', 'tomato', 'onion', 'potato']
        prices = {}
        
        for crop in crops:
            price_data = get_best_market_price(state, district, crop)
            if price_data.get('success'):
                prices[crop] = {
                    'price': price_data['price'],
                    'source': price_data['source'],
                    'confidence': price_data.get('confidence', 'medium')
                }
        
        return jsonify({
            'success': True,
            'prices': prices,
            'location': f'{district}, {state}',
            'date': datetime.now().strftime('%Y-%m-%d')
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/water-recommendation/<crop_name>')
@require_login
def water_recommendation(crop_name):
    """Water recommendation page for specific crop"""
    # Handle URL encoded crop names and normalize them
    import urllib.parse
    crop_name = urllib.parse.unquote(crop_name)
    
    # Normalize crop name
    crop_name_normalized = crop_name.lower().replace(' ', '').replace('(', '').replace(')', '').replace('pigeon', 'tur')
    
    # Map common variations
    crop_mappings = {
        'pigeonpea': 'tur',
        'turpigeonpea': 'tur', 
        'soyabean': 'soybean',
        'groundnut': 'groundnut',
        'jowar': 'jowar'
    }
    
    final_crop_name = crop_mappings.get(crop_name_normalized, crop_name_normalized)
    
    return render_template('water_recommendation.html', crop_name=final_crop_name)

@app.route('/api/calculate-water-requirement', methods=['POST'])
@require_login
def calculate_water_requirement():
    """Calculate water requirement based on crop, land area, and growth stage"""
    try:
        data = request.get_json()
        crop_name = data.get('crop_name', '').lower()
        land_area = float(data.get('land_area', 1))
        growth_stage = data.get('growth_stage', 'vegetative')
        soil_type = data.get('soil_type', 'loamy')
        season = data.get('season', 'kharif')
        irrigation_method = data.get('irrigation_method', 'flood')
        
        # Calculate water requirement
        water_data = get_comprehensive_water_requirement(
            crop_name, land_area, growth_stage, soil_type, season, irrigation_method
        )
        
        return jsonify({
            'success': True,
            'water_data': water_data,
            'generated_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/get-location-data/<state>/<district>/<block>/<village>')
@require_login
def get_location_data(state, district, block, village):
    """Get soil and climate data for specific location"""
    try:
        excel_file = Path(ROOT) / "cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        df.columns = df.columns.str.strip()
        
        # Find matching location
        location_data = df[
            (df['STATE'] == state) & 
            (df['DISTRICT NAME'] == district) & 
            (df['BLOCK NAME'] == block) & 
            (df['VILLAGE NAME'] == village)
        ]
        
        if location_data.empty:
            return jsonify({'success': False, 'error': 'Location not found'})
        
        # Get first matching row
        row = location_data.iloc[0]
        
        # Extract soil and climate data
        soil_data = {
            'nitrogen': row.get('NITROGEN', 'Medium'),
            'phosphorus': row.get('PHOSPHORUS', 'Medium'),
            'potassium': row.get('POTASSIUM', 'Medium'),
            'ph': row.get('pH', 'Neutral'),
            'organic_carbon': row.get('OC', 'Medium'),
            'ec': row.get('EC', 'Non-saline')
        }
        
        # Extract crop suitability
        crop_suitability = {}
        crop_columns = ['Sugarcane', 'Cotton', 'Soyabean', 'Rice', 'Jowar', 'Tur (Pigeon Pea)', 'Wheat', 'Groundnut', 'Onion', 'Tomato', 'Potato', 'Garlic']
        
        for crop in crop_columns:
            if crop in row:
                crop_suitability[crop.lower().replace(' ', '_').replace('(', '').replace(')', '')] = row[crop]
        
        # Extract climate data
        climate_data = {
            'summer_temp': row.get('SUMMER TEMPERATURE', 'Medium'),
            'winter_temp': row.get('WINTER TEMPERATURE', 'Medium'),
            'monsoon_temp': row.get('MONSOON TEMPERATURE', 'Medium'),
            'rainfall': row.get('Rainfall overall', 'Medium')
        }
        
        return jsonify({
            'success': True,
            'soil_data': soil_data,
            'climate_data': climate_data,
            'crop_suitability': crop_suitability,
            'location': {
                'state': state,
                'district': district,
                'block': block,
                'village': village
            }
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

def fetch_live_market_price(state, district, crop):
    """Fetch live market prices from government APIs and market data sources"""
    try:
        # Map crop names to API format
        crop_mapping = {
            'rice': 'Rice',
            'wheat': 'Wheat', 
            'cotton': 'Cotton',
            'sugarcane': 'Sugarcane',
            'soybean': 'Soyabean',
            'groundnut': 'Groundnut',
            'tomato': 'Tomato',
            'onion': 'Onion',
            'potato': 'Potato'
        }
        
        api_crop = crop_mapping.get(crop.lower(), crop)
        
        # Try multiple API sources in order of preference
        price_data = None
        
        # 1. Try AgMarkNet API (Government of India)
        price_data = fetch_agmarknet_price(state, district, api_crop)
        
        # 2. Try Commodity APIs as fallback
        if not price_data:
            price_data = fetch_commodity_api_price(api_crop, state)
        
        # 3. Try Web scraping from reliable sources
        if not price_data:
            price_data = fetch_scraped_price(state, district, api_crop)
        
        # 4. Enhanced simulation with real market patterns
        if not price_data:
            price_data = get_enhanced_simulated_price(crop, state, district)
        
        return price_data
        
    except Exception as e:
        print(f"Error fetching live price: {e}")
        return get_enhanced_simulated_price(crop, state, district)

def fetch_agmarknet_price(state, district, crop):
    """Fetch prices from AgMarkNet API (Government of India)"""
    try:
        # AgMarkNet API endpoints
        base_url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        
        # Parameters for API call
        params = {
            'api-key': 'YOUR_API_KEY',  # You need to register at data.gov.in
            'format': 'json',
            'filters[state]': state,
            'filters[district]': district,
            'filters[commodity]': crop,
            'limit': 10
        }
        
        # Note: You need to register at https://data.gov.in/ to get API key
        # For now, return None to use fallback methods
        return None
        
    except Exception as e:
        print(f"AgMarkNet API error: {e}")
        return None

def fetch_commodity_api_price(crop, state):
    """Fetch prices from commodity price APIs"""
    try:
        # You can use APIs like:
        # - CommodityAPI.com
        # - Alpha Vantage Commodities
        # - Quandl/NASDAQ Data Link
        
        # Example with a hypothetical commodity API
        # api_url = f"https://api.commodityapi.com/api/latest?access_key=YOUR_KEY&symbols={crop}&base=INR"
        
        # For demonstration, return None to use next fallback
        return None
        
    except Exception as e:
        print(f"Commodity API error: {e}")
        return None

def fetch_scraped_price(state, district, crop):
    """Fetch prices by scraping reliable agricultural websites"""
    try:
        # You can scrape from:
        # - agmarknet.gov.in
        # - commodityindia.com
        # - State agriculture department websites
        
        # For now, return None to use simulation
        return None
        
    except Exception as e:
        print(f"Web scraping error: {e}")
        return None

def get_enhanced_simulated_price(crop, state, district):
    """Enhanced price simulation with realistic market patterns"""
    try:
        import random
        from datetime import datetime, timedelta
        
        # Base prices (₹ per quintal) - updated with 2025 market rates
        base_prices = {
            'rice': 2800,
            'wheat': 2400, 
            'cotton': 6500,
            'sugarcane': 380,
            'soybean': 6200,
            'groundnut': 7200,
            'tomato': 2500,
            'onion': 1800,
            'potato': 2200
        }
        
        # State-wise price multipliers (based on market analysis)
        state_multipliers = {
            'Maharashtra': 1.12,
            'Punjab': 1.08,
            'Haryana': 1.06,
            'Uttar Pradesh': 0.94,
            'Madhya Pradesh': 0.88,
            'Rajasthan': 0.92,
            'Gujarat': 1.15,
            'Karnataka': 1.02,
            'Andhra Pradesh': 0.96,
            'Tamil Nadu': 1.08,
            'West Bengal': 0.90,
            'Bihar': 0.85,
            'Odisha': 0.88
        }
        
        # Seasonal variations (month-based)
        current_month = datetime.now().month
        seasonal_multipliers = {
            'rice': [0.95, 0.92, 0.90, 0.95, 1.05, 1.10, 1.15, 1.12, 1.08, 1.05, 1.00, 0.98],
            'wheat': [1.20, 1.25, 1.30, 1.20, 1.10, 1.00, 0.85, 0.80, 0.85, 0.90, 1.00, 1.15],
            'tomato': [1.30, 1.20, 1.10, 0.90, 0.80, 0.85, 0.95, 1.05, 1.15, 1.25, 1.35, 1.30],
            'onion': [1.15, 1.20, 1.25, 1.30, 1.20, 1.00, 0.85, 0.80, 0.85, 0.95, 1.05, 1.10]
        }
        
        base_price = base_prices.get(crop.lower(), 2500)
        state_mult = state_multipliers.get(state, 1.0)
        
        # Apply seasonal variation if available
        seasonal_mult = 1.0
        if crop.lower() in seasonal_multipliers:
            seasonal_mult = seasonal_multipliers[crop.lower()][current_month - 1]
        
        # Market volatility (±8% daily variation)
        daily_variance = random.uniform(0.92, 1.08)
        
        # Calculate final price
        final_price = int(base_price * state_mult * seasonal_mult * daily_variance)
        
        return {
            'price': final_price,
            'market': f'{district} Regional Market',
            'date': datetime.now().strftime('%Y-%m-%d'),
            'source_type': 'enhanced_simulation'
        }
        
    except Exception as e:
        print(f"Enhanced simulation error: {e}")
        return {
            'price': 2500,
            'market': 'Default Market',
            'date': datetime.now().strftime('%Y-%m-%d'),
            'source_type': 'fallback'
        }

def get_best_market_price(state, district, crop):
    """Get the best available market price from multiple sources"""
    try:
        # Try to get live price first
        live_price = fetch_live_market_price(state, district, crop)
        
        if live_price and live_price.get('price'):
            return {
                'success': True,
                'price': live_price['price'],
                'source': 'live' if live_price.get('source_type') != 'enhanced_simulation' else 'simulated',
                'market': live_price.get('market', f'{district} Market'),
                'date': live_price.get('date', datetime.now().strftime('%Y-%m-%d')),
                'confidence': 'high' if 'simulation' not in live_price.get('source_type', '') else 'medium'
            }
        
        # Fallback to historical data
        historical_price = get_historical_crop_price(crop, state)
        
        return {
            'success': True,
            'price': historical_price,
            'source': 'historical',
            'market': f'{district} Historical Average',
            'date': datetime.now().strftime('%Y-%m-%d'),
            'confidence': 'low'
        }
        
    except Exception as e:
        print(f"Error getting best market price: {e}")
        return {
            'success': False,
            'error': str(e),
            'price': 2500,  # Default fallback
            'source': 'default',
            'market': 'Default',
            'date': datetime.now().strftime('%Y-%m-%d'),
            'confidence': 'low'
        }

def get_historical_crop_price(crop, state):
    """Get historical average price for crop in state with 2025 market rates"""
    # Updated state-wise price variations (based on 2025 market analysis)
    state_multipliers = {
        'Maharashtra': 1.12,
        'Punjab': 1.08,
        'Haryana': 1.06,
        'Uttar Pradesh': 0.94,
        'Madhya Pradesh': 0.88,
        'Rajasthan': 0.92,
        'Gujarat': 1.15,
        'Karnataka': 1.02,
        'Andhra Pradesh': 0.96,
        'Tamil Nadu': 1.08,
        'West Bengal': 0.90,
        'Bihar': 0.85,
        'Odisha': 0.88,
        'Telangana': 0.98,
        'Kerala': 1.20,
        'Assam': 0.85
    }
    
    # Updated base prices for 2025 (₹ per quintal)
    base_prices = {
        'rice': 2800,
        'wheat': 2400,
        'cotton': 6500,
        'sugarcane': 380,
        'soybean': 6200,
        'groundnut': 7200,
        'tomato': 2500,
        'onion': 1800,
        'potato': 2200,
        'jowar': 2600,
        'garlic': 8000
    }
    
    base_price = base_prices.get(crop.lower(), 2500)
    multiplier = state_multipliers.get(state, 1.0)
    
    return int(base_price * multiplier)

# ---------------------------
# YieldWise Supporting Functions
# ---------------------------

def get_crop_market_insights(crop, current_price):
    """Generate market insights for a specific crop"""
    # Base prices for comparison (₹ per quintal)
    base_prices = {
        'rice': 2800, 'wheat': 2400, 'cotton': 6500, 'sugarcane': 380,
        'soybean': 6200, 'groundnut': 7200, 'tomato': 2500, 'onion': 1800,
        'potato': 2200, 'jowar': 2600, 'garlic': 8000, 'tur': 5800
    }
    
    base_price = base_prices.get(crop.lower(), 2500)
    price_variance = ((current_price - base_price) / base_price) * 100
    
    if price_variance > 15:
        trend = 'High - Good selling opportunity'
        color = 'green'
    elif price_variance > 5:
        trend = 'Above Average - Favorable market'
        color = 'lightgreen'
    elif price_variance < -15:
        trend = 'Low - Consider storing or alternative markets'
        color = 'red'
    elif price_variance < -5:
        trend = 'Below Average - Wait for better prices'
        color = 'orange'
    else:
        trend = 'Stable - Normal market conditions'
        color = 'blue'
    
    return {
        'trend': trend,
        'color': color,
        'variance_percent': round(price_variance, 1),
        'recommendation': get_price_recommendation(price_variance)
    }

def get_price_recommendation(variance):
    """Get price-based recommendation"""
    if variance > 20:
        return "Excellent time to sell. Prices are significantly above average."
    elif variance > 10:
        return "Good time to sell. Market conditions are favorable."
    elif variance < -20:
        return "Consider storage or wait for price recovery if possible."
    elif variance < -10:
        return "Below average prices. Explore direct marketing options."
    else:
        return "Normal market conditions. Proceed with regular selling."

def get_price_trend(crop):
    """Get simplified price trend for crop"""
    import random
    trends = ['rising', 'stable', 'declining']
    return random.choice(trends)  # In real implementation, use historical data

def analyze_single_crop_profitability(crop, state, district, farm_size):
    """Analyze profitability for a single crop"""
    # Get current market price
    price_data = get_enhanced_simulated_price(crop, state, district)
    current_price = price_data['price']
    
    # Crop-specific data
    crop_specs = {
        'rice': {'yield': 20, 'seed_cost': 3000, 'fert_cost': 8000, 'labor_cost': 12000, 'other_cost': 5000},
        'wheat': {'yield': 15, 'seed_cost': 2500, 'fert_cost': 6000, 'labor_cost': 10000, 'other_cost': 4000},
        'cotton': {'yield': 12, 'seed_cost': 4000, 'fert_cost': 10000, 'labor_cost': 15000, 'other_cost': 6000},
        'sugarcane': {'yield': 600, 'seed_cost': 15000, 'fert_cost': 20000, 'labor_cost': 25000, 'other_cost': 10000},
        'soybean': {'yield': 14, 'seed_cost': 3500, 'fert_cost': 7000, 'labor_cost': 11000, 'other_cost': 4500},
        'groundnut': {'yield': 18, 'seed_cost': 5000, 'fert_cost': 8000, 'labor_cost': 13000, 'other_cost': 5500},
        'tomato': {'yield': 250, 'seed_cost': 8000, 'fert_cost': 15000, 'labor_cost': 20000, 'other_cost': 8000},
        'onion': {'yield': 200, 'seed_cost': 6000, 'fert_cost': 12000, 'labor_cost': 18000, 'other_cost': 7000}
    }
    
    specs = crop_specs.get(crop, crop_specs['rice'])
    
    # Calculate per acre costs
    total_cost_per_acre = specs['seed_cost'] + specs['fert_cost'] + specs['labor_cost'] + specs['other_cost']
    revenue_per_acre = specs['yield'] * current_price
    profit_per_acre = revenue_per_acre - total_cost_per_acre
    
    # Scale to farm size
    total_cost = total_cost_per_acre * farm_size
    total_revenue = revenue_per_acre * farm_size
    estimated_profit = profit_per_acre * farm_size
    
    roi = (estimated_profit / total_cost * 100) if total_cost > 0 else 0
    
    return {
        'crop': crop,
        'crop_name': crop.title(),
        'estimated_profit': estimated_profit,
        'roi': round(roi, 1),
        'total_revenue': total_revenue,
        'total_cost': total_cost,
        'profit_per_acre': profit_per_acre,
        'current_price': current_price,
        'expected_yield': specs['yield'],
        'risk_factor': get_crop_risk_factor(crop)
    }

def get_crop_risk_factor(crop):
    """Get risk factor for different crops"""
    risk_factors = {
        'rice': 'Low', 'wheat': 'Low', 'cotton': 'Medium', 'sugarcane': 'Low',
        'soybean': 'Medium', 'groundnut': 'Medium', 'tomato': 'High', 'onion': 'High'
    }
    return risk_factors.get(crop, 'Medium')

def get_comprehensive_water_requirement(crop_name, land_area, growth_stage, soil_type, season, irrigation_method):
    """Calculate comprehensive water requirement for crop based on multiple factors"""
    
    # Water requirement data per hectare per day (liters) - based on crop and growth stage
    crop_water_requirements = {
        'rice': {
            'vegetative': 15000,  # High water requirement
            'flowering': 18000,
            'maturity': 12000,
            'total_season': 1200000,  # 1200 mm equivalent
            'critical_stages': ['transplanting', 'flowering', 'grain_filling']
        },
        'wheat': {
            'vegetative': 8000,
            'flowering': 10000,
            'maturity': 6000,
            'total_season': 450000,  # 450 mm equivalent
            'critical_stages': ['tillering', 'jointing', 'grain_filling']
        },
        'cotton': {
            'vegetative': 10000,
            'flowering': 15000,
            'maturity': 8000,
            'total_season': 700000,  # 700 mm equivalent
            'critical_stages': ['square_formation', 'flowering', 'boll_development']
        },
        'sugarcane': {
            'vegetative': 20000,
            'flowering': 25000,
            'maturity': 15000,
            'total_season': 1800000,  # 1800 mm equivalent
            'critical_stages': ['germination', 'tillering', 'grand_growth']
        },
        'soybean': {
            'vegetative': 8000,
            'flowering': 12000,
            'maturity': 6000,
            'total_season': 450000,  # 450 mm equivalent
            'critical_stages': ['flowering', 'pod_filling']
        },
        'groundnut': {
            'vegetative': 9000,
            'flowering': 12000,
            'maturity': 7000,
            'total_season': 500000,  # 500 mm equivalent
            'critical_stages': ['pegging', 'pod_development']
        },
        'tomato': {
            'vegetative': 12000,
            'flowering': 15000,
            'maturity': 10000,
            'total_season': 600000,  # 600 mm equivalent
            'critical_stages': ['flowering', 'fruit_setting', 'fruit_development']
        },
        'onion': {
            'vegetative': 8000,
            'flowering': 10000,
            'maturity': 6000,
            'total_season': 400000,  # 400 mm equivalent
            'critical_stages': ['bulb_initiation', 'bulb_development']
        },
        'potato': {
            'vegetative': 10000,
            'flowering': 12000,
            'maturity': 8000,
            'total_season': 500000,  # 500 mm equivalent
            'critical_stages': ['tuber_initiation', 'tuber_bulking']
        },
        'garlic': {
            'vegetative': 7000,
            'flowering': 9000,
            'maturity': 5000,
            'total_season': 350000,  # 350 mm equivalent
            'critical_stages': ['bulb_formation', 'bulb_development']
        }
    }
    
    # Soil type multipliers (water retention capacity)
    soil_multipliers = {
        'sandy': 1.4,      # Poor water retention
        'sandy_dry': 1.6,  # Very poor retention
        'loamy': 1.0,      # Ideal water retention
        'loamy_moist': 0.9,
        'clay': 0.8,       # Good water retention
        'black_cotton': 0.7,  # Excellent retention
        'red_soil': 1.2,
        'laterite': 1.3
    }
    
    # Season multipliers (evapotranspiration rates)
    season_multipliers = {
        'kharif': 1.2,   # Higher ET in monsoon/summer
        'rabi': 0.8,     # Lower ET in winter
        'summer': 1.5    # Highest ET in summer
    }
    
    # Irrigation method efficiency
    irrigation_efficiency = {
        'flood': 0.4,      # 40% efficiency
        'furrow': 0.6,     # 60% efficiency
        'sprinkler': 0.75, # 75% efficiency
        'drip': 0.9        # 90% efficiency
    }
    
    # Get base water requirement
    crop_data = crop_water_requirements.get(crop_name, crop_water_requirements['wheat'])
    daily_requirement = crop_data.get(growth_stage, crop_data['vegetative'])
    
    # Apply multipliers
    soil_mult = soil_multipliers.get(soil_type, 1.0)
    season_mult = season_multipliers.get(season, 1.0)
    efficiency = irrigation_efficiency.get(irrigation_method, 0.6)
    
    # Calculate actual water requirement
    daily_water_per_hectare = daily_requirement * soil_mult * season_mult
    daily_water_total = daily_water_per_hectare * land_area
    
    # Account for irrigation efficiency
    daily_water_needed = daily_water_total / efficiency
    
    # Weekly and monthly projections
    weekly_water = daily_water_needed * 7
    monthly_water = daily_water_needed * 30
    
    # Season total
    season_total = crop_data['total_season'] * land_area * soil_mult * season_mult / efficiency
    
    # Generate irrigation schedule
    irrigation_schedule = generate_irrigation_schedule(
        crop_name, growth_stage, daily_water_needed, irrigation_method
    )
    
    # Water conservation tips
    conservation_tips = get_water_conservation_tips(crop_name, soil_type, irrigation_method)
    
    # Cost estimation (₹ per 1000 liters)
    water_cost_per_1000l = get_water_cost_estimate(irrigation_method)
    daily_cost = (daily_water_needed / 1000) * water_cost_per_1000l
    monthly_cost = daily_cost * 30
    
    return {
        'crop_name': crop_name.title(),
        'land_area': land_area,
        'growth_stage': growth_stage.replace('_', ' ').title(),
        'soil_type': soil_type.replace('_', ' ').title(),
        'season': season.title(),
        'irrigation_method': irrigation_method.replace('_', ' ').title(),
        'water_requirements': {
            'daily_liters': int(daily_water_needed),
            'daily_per_hectare': int(daily_water_per_hectare),
            'weekly_liters': int(weekly_water),
            'monthly_liters': int(monthly_water),
            'season_total_liters': int(season_total)
        },
        'irrigation_schedule': irrigation_schedule,
        'conservation_tips': conservation_tips,
        'cost_estimate': {
            'daily_cost': round(daily_cost, 2),
            'monthly_cost': round(monthly_cost, 2),
            'cost_per_1000l': water_cost_per_1000l
        },
        'efficiency_data': {
            'method_efficiency': f"{efficiency * 100}%",
            'water_saved_with_drip': int((daily_water_needed * (1 - 0.9/efficiency)) if efficiency < 0.9 else 0),
            'cost_saved_with_drip': round((daily_cost * (1 - 0.9/efficiency)) if efficiency < 0.9 else 0, 2)
        },
        'critical_stages': crop_data['critical_stages']
    }

def generate_irrigation_schedule(crop_name, growth_stage, daily_water_needed, irrigation_method):
    """Generate optimal irrigation schedule"""
    
    schedule_patterns = {
        'flood': {'frequency': 'Every 7-10 days', 'duration': '2-3 hours', 'best_time': '6-8 AM'},
        'furrow': {'frequency': 'Every 5-7 days', 'duration': '3-4 hours', 'best_time': '6-9 AM'},
        'sprinkler': {'frequency': 'Every 2-3 days', 'duration': '1-2 hours', 'best_time': '6-8 AM, 6-8 PM'},
        'drip': {'frequency': 'Daily', 'duration': '30-60 minutes', 'best_time': '6-7 AM, 7-8 PM'}
    }
    
    pattern = schedule_patterns.get(irrigation_method, schedule_patterns['furrow'])
    
    # Growth stage specific adjustments
    stage_adjustments = {
        'vegetative': 'Moderate frequency, ensure consistent moisture',
        'flowering': 'Critical stage - never skip irrigation, increase frequency',
        'maturity': 'Reduce frequency gradually, avoid water stress'
    }
    
    return {
        'frequency': pattern['frequency'],
        'duration': pattern['duration'],
        'best_time': pattern['best_time'],
        'stage_note': stage_adjustments.get(growth_stage, 'Maintain regular schedule'),
        'weekly_sessions': get_weekly_sessions(irrigation_method),
        'special_instructions': get_special_irrigation_instructions(crop_name, growth_stage)
    }

def get_weekly_sessions(irrigation_method):
    """Get number of irrigation sessions per week"""
    sessions = {
        'flood': 1,
        'furrow': 2,
        'sprinkler': 3,
        'drip': 7
    }
    return sessions.get(irrigation_method, 2)

def get_special_irrigation_instructions(crop_name, growth_stage):
    """Get crop and stage specific irrigation instructions"""
    instructions = {
        'rice': {
            'vegetative': 'Maintain 2-5 cm standing water',
            'flowering': 'Ensure continuous flooding during flowering',
            'maturity': 'Drain field 15 days before harvest'
        },
        'wheat': {
            'vegetative': 'Light frequent irrigation for establishment',
            'flowering': 'Critical irrigation at flowering and grain filling',
            'maturity': 'Stop irrigation 2 weeks before harvest'
        },
        'cotton': {
            'vegetative': 'Deep but less frequent irrigation',
            'flowering': 'Increase frequency during square and boll formation',
            'maturity': 'Reduce irrigation to improve fiber quality'
        }
    }
    
    crop_instructions = instructions.get(crop_name, {})
    return crop_instructions.get(growth_stage, 'Follow standard irrigation practices')

def get_water_conservation_tips(crop_name, soil_type, irrigation_method):
    """Get water conservation tips based on crop and conditions"""
    tips = [
        '🌱 Use mulching to reduce evaporation by 40-60%',
        '⏰ Irrigate during early morning or late evening',
        '📊 Monitor soil moisture using simple tools',
        '🌾 Consider drought-resistant varieties if available'
    ]
    
    # Method-specific tips
    if irrigation_method != 'drip':
        tips.append('💧 Consider upgrading to drip irrigation for 40-50% water savings')
    
    if soil_type in ['sandy', 'sandy_dry']:
        tips.extend([
            '🌾 Add organic matter to improve water retention',
            '💧 Use more frequent, shorter irrigation cycles'
        ])
    
    if crop_name in ['rice', 'sugarcane']:
        tips.append('🌊 Consider alternate wetting and drying (AWD) method')
    
    # Seasonal tips
    current_month = datetime.now().month
    if current_month in [4, 5, 6]:  # Summer months
        tips.append('☀️ Increase irrigation frequency during hot summer months')
    elif current_month in [11, 12, 1, 2]:  # Winter months
        tips.append('❄️ Reduce irrigation frequency during cool winter months')
    
    return tips[:6]  # Return top 6 tips

def get_water_cost_estimate(irrigation_method):
    """Get estimated cost per 1000 liters based on irrigation method"""
    # Cost includes electricity, maintenance, and water charges
    costs = {
        'flood': 8,      # ₹8 per 1000L (low efficiency, high volume)
        'furrow': 10,    # ₹10 per 1000L
        'sprinkler': 15, # ₹15 per 1000L (equipment cost)
        'drip': 20       # ₹20 per 1000L (high efficiency, equipment cost)
    }
    return costs.get(irrigation_method, 12)

@app.route('/api/get-weather-data/<state>/<district>')
@require_login
def get_weather_data(state, district):
    """Get weather data for water requirement calculations"""
    try:
        # Simulated weather data (in production, integrate with weather APIs)
        import random
        
        current_temp = random.randint(20, 40)
        humidity = random.randint(40, 90)
        rainfall_forecast = random.randint(0, 50)
        wind_speed = random.randint(5, 25)
        
        # Calculate weather-based water adjustment
        weather_multiplier = 1.0
        
        if current_temp > 35:
            weather_multiplier += 0.3  # Hot weather needs more water
        elif current_temp < 20:
            weather_multiplier -= 0.2  # Cool weather needs less water
            
        if humidity < 50:
            weather_multiplier += 0.2  # Low humidity needs more water
        elif humidity > 80:
            weather_multiplier -= 0.1  # High humidity needs less water
            
        if rainfall_forecast > 20:
            weather_multiplier -= 0.4  # Expected rain reduces irrigation need
            
        weather_multiplier = max(0.5, min(2.0, weather_multiplier))  # Keep within reasonable range
        
        return jsonify({
            'success': True,
            'weather_data': {
                'temperature': current_temp,
                'humidity': humidity,
                'rainfall_forecast': rainfall_forecast,
                'wind_speed': wind_speed,
                'weather_multiplier': round(weather_multiplier, 2)
            },
            'recommendations': get_weather_based_recommendations(current_temp, humidity, rainfall_forecast)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

def get_weather_based_recommendations(temp, humidity, rainfall):
    """Get weather-based irrigation recommendations"""
    recommendations = []
    
    if temp > 35:
        recommendations.append("🌡️ High temperature detected - increase irrigation frequency")
        recommendations.append("⏰ Irrigate early morning and late evening to reduce evaporation")
    
    if humidity < 50:
        recommendations.append("💨 Low humidity - plants will lose water faster")
        recommendations.append("🌿 Consider misting for sensitive crops")
    
    if rainfall > 20:
        recommendations.append("🌧️ Rain expected - reduce or skip next irrigation")
        recommendations.append("💧 Monitor soil moisture before resuming irrigation")
    elif rainfall < 5:
        recommendations.append("☀️ No rain expected - maintain regular irrigation schedule")
    
    return recommendations

@app.route('/api/soil-moisture-guide/<crop_name>')
@require_login
def soil_moisture_guide(crop_name):
    """Get soil moisture monitoring guide for specific crop"""
    try:
        # Soil moisture requirements by crop (% field capacity)
        moisture_requirements = {
            'rice': {
                'optimal_range': '80-100%',
                'critical_threshold': '70%',
                'method': 'Standing water 2-5cm deep',
                'monitoring_depth': '0-15cm'
            },
            'wheat': {
                'optimal_range': '60-80%',
                'critical_threshold': '50%', 
                'method': 'Soil should be moist but not waterlogged',
                'monitoring_depth': '0-30cm'
            },
            'cotton': {
                'optimal_range': '50-70%',
                'critical_threshold': '40%',
                'method': 'Allow soil to dry between irrigations',
                'monitoring_depth': '0-60cm'
            },
            'tomato': {
                'optimal_range': '70-85%',
                'critical_threshold': '60%',
                'method': 'Consistent moisture, avoid water stress',
                'monitoring_depth': '0-30cm'
            },
            'onion': {
                'optimal_range': '60-75%',
                'critical_threshold': '50%',
                'method': 'Moderate moisture, reduce before harvest',
                'monitoring_depth': '0-20cm'
            }
        }
        
        crop_data = moisture_requirements.get(crop_name.lower(), {
            'optimal_range': '60-80%',
            'critical_threshold': '50%',
            'method': 'Maintain moderate soil moisture',
            'monitoring_depth': '0-30cm'
        })
        
        # Simple monitoring techniques
        monitoring_tips = [
            "👆 Finger Test: Insert finger 2-3 inches into soil",
            "🥄 Spade Test: Dig small hole and check soil color/texture", 
            "📏 Stick Test: Insert wooden stick and check moisture line",
            "⚖️ Weight Test: Compare dry vs wet soil container weights",
            "👁️ Visual Test: Look for soil cracking or plant wilting signs"
        ]
        
        return jsonify({
            'success': True,
            'crop': crop_name.title(),
            'moisture_requirements': crop_data,
            'monitoring_tips': monitoring_tips,
            'irrigation_indicators': get_irrigation_indicators(crop_name)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

def get_irrigation_indicators(crop_name):
    """Get signs that indicate when to irrigate"""
    general_indicators = [
        "🍃 Leaves appear dull or slightly wilted in morning",
        "🌱 Soil surface appears dry and cracked",
        "📏 Finger test shows dry soil 2-3 inches deep",
        "📉 Plant growth appears slower than normal"
    ]
    
    crop_specific = {
        'rice': ["💧 Water level in field drops below 2cm"],
        'tomato': ["🍅 Fruit development slows or stops", "🌿 Lower leaves start yellowing"],
        'cotton': ["🌸 Flower and boll drop increases", "🍃 Leaves curl during midday"],
        'wheat': ["🌾 Tillering is reduced", "🍃 Leaf rolling observed"],
        'onion': ["🧅 Bulb development slows", "🍃 Tip burning on leaves"]
    }
    
    specific = crop_specific.get(crop_name.lower(), [])
    return {
        'general_signs': general_indicators,
        'crop_specific_signs': specific
    }

def get_current_market_conditions():
    """Get current overall market conditions"""
    return {
        'overall_trend': 'Stable',
        'demand': 'Moderate',
        'supply': 'Adequate',
        'seasonal_factor': 'Post-harvest period',
        'export_demand': 'Good',
        'storage_costs': 'Moderate'
    }

def generate_smart_recommendations(data):
    """Generate smart farming recommendations based on analysis"""
    recommendations = []
    
    # ROI-based recommendations
    if data['roi'] < 0:
        recommendations.append({
            'category': 'Critical',
            'icon': '🚨',
            'title': 'Immediate Action Required',
            'description': 'Current crop selection may result in losses. Consider switching to more profitable alternatives.',
            'priority': 'high'
        })
    elif data['roi'] < 15:
        recommendations.append({
            'category': 'Optimization',
            'icon': '⚡',
            'title': 'Cost Optimization Needed',
            'description': 'Focus on reducing input costs through bulk purchasing and efficient resource usage.',
            'priority': 'medium'
        })
    elif data['roi'] > 30:
        recommendations.append({
            'category': 'Expansion',
            'icon': '📈',
            'title': 'Scale Up Opportunity',
            'description': 'Excellent returns detected. Consider expanding cultivation area or investing in better infrastructure.',
            'priority': 'low'
        })
    
    # Farm size recommendations
    if data['farm_area'] < 2:
        recommendations.append({
            'category': 'Scale',
            'icon': '🤝',
            'title': 'Cooperative Farming',
            'description': 'Small farm size limits economies of scale. Consider cooperative farming or contract cultivation.',
            'priority': 'medium'
        })
    
    # Cost structure recommendations
    if data['total_cost'] > 200000:
        recommendations.append({
            'category': 'Finance',
            'icon': '💰',
            'title': 'Financial Planning',
            'description': 'High investment detected. Ensure adequate cash flow and consider crop insurance.',
            'priority': 'medium'
        })
    
    return recommendations

def get_crop_cost_benchmarks(crop):
    """Get cost benchmarks and industry standards for specific crop"""
    # Industry benchmarks per acre (₹)
    benchmarks = {
        'rice': {
            'seed_cost_range': [2500, 4000],
            'fertilizer_cost_range': [6000, 10000],
            'labor_cost_range': [10000, 15000],
            'total_cost_range': [25000, 35000],
            'avg_yield_range': [18, 25],
            'break_even_price': 1800
        },
        'wheat': {
            'seed_cost_range': [2000, 3500],
            'fertilizer_cost_range': [5000, 8000],
            'labor_cost_range': [8000, 12000],
            'total_cost_range': [20000, 28000],
            'avg_yield_range': [12, 18],
            'break_even_price': 1900
        },
        'cotton': {
            'seed_cost_range': [3500, 5000],
            'fertilizer_cost_range': [8000, 12000],
            'labor_cost_range': [12000, 18000],
            'total_cost_range': [30000, 40000],
            'avg_yield_range': [10, 15],
            'break_even_price': 3000
        }
    }
    
    return benchmarks.get(crop, {
        'seed_cost_range': [2000, 5000],
        'fertilizer_cost_range': [5000, 12000],
        'labor_cost_range': [8000, 15000],
        'total_cost_range': [20000, 40000],
        'avg_yield_range': [10, 20],
        'break_even_price': 2000
    })

@app.route('/index')
@require_login
def index():
    return render_template('index.html')

@app.route('/manual-input')
@require_login
def manual_input():
    attributes = {
        "Nitrogen": ["High (81—100%)", "Medium (51—80%)", "Low (0—50%)"],
        "Phosphorus": ["High (81—100%)", "Medium (41—80%)", "Low (0—40%)"],
        "Potassium": ["High (81—100%)", "Medium (31—80%)", "Low (0—30%)"],
        "OC": ["High (> 0.75%)", "Medium (0.5—0.75%)", "Low (< 0.5%)"],
        "EC": ["Non-Saline (< 4 dS/m)", "Saline (≥ 4 dS/m)"],
        "pH": ["Alkaline (above 7.5)", "Neutral (6.5—7.5)", "Acidic (below 6.5)"],
        "Copper": ["Sufficient (81—100%)", "Deficient (0—50%)"],
        "Boron": ["Sufficient (81—100%)", "Deficient (0—50%)"],
        "Sulphur": ["Sufficient (81—100%)", "Deficient (0—50%)"],
        "Iron": ["Sufficient (81—100%)", "Deficient (0—50%)"],
        "Zinc": ["Sufficient (86—100%)", "Deficient (0—60%)"],
        "Manganese": ["Sufficient (81—100%)", "Deficient (0—50%)"],
        "Temperature_Summer": [
            "Low (< 28°C — Too cool for summer crops)",
            "Medium (28—35°C — Ideal for warm-season crops)",
            "High (> 35°C — Heat stress risk)"
        ],
        "Temperature_Winter": [
            "Low (< 10°C — Too cold for most crops)",
            "Medium (10—20°C — Ideal for rabi crops)",
            "High (> 20°C — May hinder wheat filling)"
        ],
        "Temperature_Monsoon": [
            "Low (< 22°C — Poor germination)",
            "Medium (22—30°C — Ideal for kharif crops)",
            "High (> 30°C — Fungal stress risk)"
        ],
        "Rainfall": [
            "High (1000—1500 mm — Ideal rainfed range)",
            "Medium (500—1000 mm — May need irrigation)",
            "Low (< 500 mm — Highly insufficient)"
        ]
    }
    return render_template('manual_input.html', attributes=attributes)

@app.route('/predict-manual', methods=['POST'])
@require_login
def predict_manual():
    raw_input = request.form.to_dict()
    print("🔍 Raw form input:", raw_input)
    form_data = normalize_input(raw_input)
    
    # Store soil data in session for dynamic Gantt chart use
    session['soil_data'] = {
        'nitrogen': raw_input.get('Nitrogen', ''),
        'phosphorus': raw_input.get('Phosphorus', ''),
        'potassium': raw_input.get('Potassium', ''),
        'organic_carbon': raw_input.get('OC', ''),
        'ec': raw_input.get('EC', ''),
        'ph': raw_input.get('pH', ''),
        'copper': raw_input.get('Copper', ''),
        'boron': raw_input.get('Boron', ''),
        'sulphur': raw_input.get('Sulphur', ''),
        'iron': raw_input.get('Iron', ''),
        'zinc': raw_input.get('Zinc', ''),
        'manganese': raw_input.get('Manganese', ''),
        'temp_summer': raw_input.get('Temperature_Summer', ''),
        'temp_winter': raw_input.get('Temperature_Winter', ''),
        'temp_monsoon': raw_input.get('Temperature_Monsoon', ''),
        'rainfall': raw_input.get('Rainfall', ''),
        'timestamp': datetime.now().isoformat()
    }
    
    # Mark that we have detailed soil analysis
    session['has_soil_analysis'] = True
    print("💾 Stored soil data in session:", session['soil_data'])
    
    crop_data = evaluate_all_crops(form_data)
    return render_template("index.html", crop_data=crop_data, manual=True)

@app.route('/data')
def get_dropdown_data():
    return jsonify(dropdown_data)

@app.route('/mandis/<state>')
def get_mandis(state):
    url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    params = {
        "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
        "format": "json",
        "filters[state]": state,
        "limit": 500
    }
    try:
        resp = requests.get(url, params=params)
        resp.raise_for_status()
        records = resp.json().get("records", [])
    except Exception as e:
        print(f"❌ Error fetching mandis: {e}")
        return jsonify([])

    mandis = sorted({r["market"] for r in records if r.get("market")})
    return jsonify(mandis)

@app.route('/crops/<state>/<mandi>')
def get_crops_for_mandi(state, mandi):
    url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    params = {
        "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
        "format": "json",
        "filters[state]": state,
        "filters[market]": mandi,
        "limit": 500
    }
    try:
        resp = requests.get(url, params=params, timeout=15)
        resp.raise_for_status()
        records = resp.json().get("records", [])
    except Exception as e:
        print(f"❌ Error fetching crops for mandi: {e}")
        return jsonify([])

    crops = sorted({r.get("commodity", "").strip() for r in records if r.get("commodity")})
    return jsonify(crops)

@app.route('/crops/<crop_name>')
@require_login
def crop_info(crop_name):
    return render_template('crops.html', crop_name=crop_name)

@app.route('/planner/<crop_name>')
@require_login
def growth_plan(crop_name):
    return render_template('planner.html', crop_name=crop_name)

# ---------------------------
# Simple Soil Type Functions
# ---------------------------

def convert_soil_type_to_params(soil_type):
    """Convert simple soil type to detailed parameters for compatibility"""
    soil_mappings = {
        'clayey_moist': {
            'pH': 'Neutral (6.5—7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'Medium (51—80%)',
            'phosphorus': 'High (81—100%)',
            'potassium': 'High (81—100%)',
            'oc': 'High (> 0.75%)',
            'zinc': 'Sufficient (81—100%)',
            'boron': 'Sufficient (86—100%)'
        },
        'clayey_dry': {
            'pH': 'Alkaline (above 7.5)',
            'EC': 'Saline (≥ 4 dS/m)',
            'nitrogen': 'Low (0—50%)',
            'phosphorus': 'Medium (41—80%)',
            'potassium': 'Medium (31—80%)',
            'oc': 'Low (< 0.5%)',
            'zinc': 'Deficient (0—50%)',
            'boron': 'Deficient (0—60%)'
        },
        'sandy_moist': {
            'pH': 'Neutral (6.5—7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'Low (0—50%)',
            'phosphorus': 'Low (0—40%)',
            'potassium': 'Low (0—30%)',
            'oc': 'Medium (0.5—0.75%)',
            'zinc': 'Deficient (0—50%)',
            'boron': 'Deficient (0—60%)'
        },
        'sandy_dry': {
            'pH': 'Alkaline (above 7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'Low (0—50%)',
            'phosphorus': 'Low (0—40%)',
            'potassium': 'Low (0—30%)',
            'oc': 'Low (< 0.5%)',
            'zinc': 'Deficient (0—50%)',
            'boron': 'Deficient (0—60%)'
        },
        'loamy_moist': {
            'pH': 'Neutral (6.5—7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'High (81—100%)',
            'phosphorus': 'High (81—100%)',
            'potassium': 'High (81—100%)',
            'oc': 'High (> 0.75%)',
            'zinc': 'Sufficient (81—100%)',
            'boron': 'Sufficient (86—100%)'
        },
        'loamy_dry': {
            'pH': 'Neutral (6.5—7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'Medium (51—80%)',
            'phosphorus': 'Medium (41—80%)',
            'potassium': 'Medium (31—80%)',
            'oc': 'Medium (0.5—0.75%)',
            'zinc': 'Sufficient (81—100%)',
            'boron': 'Sufficient (86—100%)'
        },
        'black_cotton': {
            'pH': 'Alkaline (above 7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'High (81—100%)',
            'phosphorus': 'High (81—100%)',
            'potassium': 'High (81—100%)',
            'oc': 'High (> 0.75%)',
            'zinc': 'Sufficient (81—100%)',
            'boron': 'Sufficient (86—100%)'
        },
        'red_soil': {
            'pH': 'Acidic (below 6.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'Medium (51—80%)',
            'phosphorus': 'Low (0—40%)',
            'potassium': 'Medium (31—80%)',
            'oc': 'Medium (0.5—0.75%)',
            'zinc': 'Deficient (0—50%)',
            'boron': 'Deficient (0—60%)'
        },
        'alluvial': {
            'pH': 'Neutral (6.5—7.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'High (81—100%)',
            'phosphorus': 'Medium (41—80%)',
            'potassium': 'High (81—100%)',
            'oc': 'High (> 0.75%)',
            'zinc': 'Sufficient (81—100%)',
            'boron': 'Sufficient (86—100%)'
        },
        'laterite': {
            'pH': 'Acidic (below 6.5)',
            'EC': 'Non-Saline (< 4 dS/m)',
            'nitrogen': 'Low (0—50%)',
            'phosphorus': 'Low (0—40%)',
            'potassium': 'Low (0—30%)',
            'oc': 'Low (< 0.5%)',
            'zinc': 'Deficient (0—50%)',
            'boron': 'Deficient (0—60%)'
        }
    }
    
    return soil_mappings.get(soil_type, soil_mappings['loamy_moist'])

def generate_simple_crop_timeline(crop_name, soil_type):
    """Generate crop timeline with soil-based adjustments"""
    
    # Base timeline data for each crop with comprehensive phases
    base_timelines = {
        'sugarcane': [
            {'id': '1', 'task_name': 'Land Preparation & Sowing', 'category': 'Preparation', 'start_date': '2025-02-01', 'end_date': '2025-02-15', 'duration': 14, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Initial Growth & Irrigation', 'category': 'Irrigation', 'start_date': '2025-02-16', 'end_date': '2025-03-15', 'duration': 28, 'dependencies': '1', 'priority': 'high'},
            {'id': '3', 'task_name': 'Fertilizer Application', 'category': 'Fertilization', 'start_date': '2025-03-16', 'end_date': '2025-04-05', 'duration': 20, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Vegetative Growth', 'category': 'Growth', 'start_date': '2025-04-06', 'end_date': '2025-08-15', 'duration': 131, 'dependencies': '3', 'priority': 'normal'},
            {'id': '5', 'task_name': 'Maturation & Sugar Development', 'category': 'Growth', 'start_date': '2025-08-16', 'end_date': '2025-11-30', 'duration': 106, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-12-01', 'end_date': '2025-12-20', 'duration': 19, 'dependencies': '5', 'priority': 'critical'}
        ],
        'cotton': [
            {'id': '1', 'task_name': 'Land Preparation & Sowing', 'category': 'Preparation', 'start_date': '2025-06-01', 'end_date': '2025-06-14', 'duration': 13, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Germination & Early Care', 'category': 'Growth', 'start_date': '2025-06-15', 'end_date': '2025-07-05', 'duration': 20, 'dependencies': '1', 'priority': 'high'},
            {'id': '3', 'task_name': 'Vegetative Growth & Fertilization', 'category': 'Fertilization', 'start_date': '2025-07-06', 'end_date': '2025-08-15', 'duration': 40, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Flowering & Pest Management', 'category': 'Pest Control', 'start_date': '2025-08-16', 'end_date': '2025-09-30', 'duration': 45, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Boll Development', 'category': 'Growth', 'start_date': '2025-10-01', 'end_date': '2025-10-25', 'duration': 24, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-10-26', 'end_date': '2025-11-15', 'duration': 20, 'dependencies': '5', 'priority': 'critical'}
        ],
        'rice': [
            {'id': '1', 'task_name': 'Nursery Preparation', 'category': 'Preparation', 'start_date': '2025-06-10', 'end_date': '2025-06-20', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Field Preparation & Puddling', 'category': 'Preparation', 'start_date': '2025-06-21', 'end_date': '2025-06-30', 'duration': 9, 'dependencies': '1', 'priority': 'critical'},
            {'id': '3', 'task_name': 'Transplanting', 'category': 'Planting', 'start_date': '2025-07-01', 'end_date': '2025-07-10', 'duration': 9, 'dependencies': '2', 'priority': 'critical'},
            {'id': '4', 'task_name': 'Tillering & Water Management', 'category': 'Irrigation', 'start_date': '2025-07-11', 'end_date': '2025-08-20', 'duration': 40, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Panicle Development', 'category': 'Growth', 'start_date': '2025-08-21', 'end_date': '2025-09-20', 'duration': 30, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Grain Filling & Maturation', 'category': 'Growth', 'start_date': '2025-09-21', 'end_date': '2025-10-15', 'duration': 24, 'dependencies': '5', 'priority': 'normal'},
            {'id': '7', 'task_name': 'Harvesting & Drying', 'category': 'Harvest', 'start_date': '2025-10-16', 'end_date': '2025-10-25', 'duration': 9, 'dependencies': '6', 'priority': 'critical'}
        ],
        'wheat': [
            {'id': '1', 'task_name': 'Land Preparation', 'category': 'Preparation', 'start_date': '2025-11-10', 'end_date': '2025-11-20', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Sowing & Irrigation', 'category': 'Planting', 'start_date': '2025-11-21', 'end_date': '2025-12-05', 'duration': 14, 'dependencies': '1', 'priority': 'critical'},
            {'id': '3', 'task_name': 'Germination & Early Growth', 'category': 'Growth', 'start_date': '2025-12-06', 'end_date': '2026-01-10', 'duration': 35, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Tillering & Fertilization', 'category': 'Fertilization', 'start_date': '2026-01-11', 'end_date': '2026-02-20', 'duration': 40, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Stem Elongation', 'category': 'Growth', 'start_date': '2026-02-21', 'end_date': '2026-03-15', 'duration': 22, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Grain Development', 'category': 'Growth', 'start_date': '2026-03-16', 'end_date': '2026-04-10', 'duration': 25, 'dependencies': '5', 'priority': 'normal'},
            {'id': '7', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2026-04-11', 'end_date': '2026-04-20', 'duration': 9, 'dependencies': '6', 'priority': 'critical'}
        ],
        'soyabean': [
            {'id': '1', 'task_name': 'Land Preparation & Sowing', 'category': 'Preparation', 'start_date': '2025-06-15', 'end_date': '2025-06-25', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Germination & Early Growth', 'category': 'Growth', 'start_date': '2025-06-26', 'end_date': '2025-07-15', 'duration': 19, 'dependencies': '1', 'priority': 'high'},
            {'id': '3', 'task_name': 'Vegetative Growth & Fertilization', 'category': 'Fertilization', 'start_date': '2025-07-16', 'end_date': '2025-08-15', 'duration': 30, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Flowering & Pod Formation', 'category': 'Growth', 'start_date': '2025-08-16', 'end_date': '2025-09-15', 'duration': 30, 'dependencies': '3', 'priority': 'normal'},
            {'id': '5', 'task_name': 'Pod Filling & Maturation', 'category': 'Growth', 'start_date': '2025-09-16', 'end_date': '2025-10-10', 'duration': 24, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-10-11', 'end_date': '2025-10-20', 'duration': 9, 'dependencies': '5', 'priority': 'critical'}
        ],
        'jowar': [
            {'id': '1', 'task_name': 'Land Preparation & Sowing', 'category': 'Preparation', 'start_date': '2025-06-01', 'end_date': '2025-06-10', 'duration': 9, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Germination & Thinning', 'category': 'Growth', 'start_date': '2025-06-11', 'end_date': '2025-06-25', 'duration': 14, 'dependencies': '1', 'priority': 'high'},
            {'id': '3', 'task_name': 'Vegetative Growth', 'category': 'Growth', 'start_date': '2025-06-26', 'end_date': '2025-07-20', 'duration': 24, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Flowering & Head Formation', 'category': 'Growth', 'start_date': '2025-07-21', 'end_date': '2025-08-15', 'duration': 25, 'dependencies': '3', 'priority': 'normal'},
            {'id': '5', 'task_name': 'Grain Development', 'category': 'Growth', 'start_date': '2025-08-16', 'end_date': '2025-09-10', 'duration': 25, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-09-11', 'end_date': '2025-09-20', 'duration': 9, 'dependencies': '5', 'priority': 'critical'}
        ],
        'tur': [
            {'id': '1', 'task_name': 'Land Preparation & Sowing', 'category': 'Preparation', 'start_date': '2025-06-25', 'end_date': '2025-07-05', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Germination & Early Growth', 'category': 'Growth', 'start_date': '2025-07-06', 'end_date': '2025-07-25', 'duration': 19, 'dependencies': '1', 'priority': 'high'},
            {'id': '3', 'task_name': 'Vegetative Growth', 'category': 'Growth', 'start_date': '2025-07-26', 'end_date': '2025-08-25', 'duration': 30, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Flowering', 'category': 'Growth', 'start_date': '2025-08-26', 'end_date': '2025-09-20', 'duration': 25, 'dependencies': '3', 'priority': 'normal'},
            {'id': '5', 'task_name': 'Pod Development', 'category': 'Growth', 'start_date': '2025-09-21', 'end_date': '2025-10-25', 'duration': 34, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-10-26', 'end_date': '2025-11-05', 'duration': 10, 'dependencies': '5', 'priority': 'critical'}
        ],
        'groundnut': [
            {'id': '1', 'task_name': 'Land Preparation & Sowing', 'category': 'Preparation', 'start_date': '2025-06-10', 'end_date': '2025-06-20', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Germination & Early Growth', 'category': 'Growth', 'start_date': '2025-06-21', 'end_date': '2025-07-10', 'duration': 19, 'dependencies': '1', 'priority': 'high'},
            {'id': '3', 'task_name': 'Pegging & Fertilization', 'category': 'Fertilization', 'start_date': '2025-07-11', 'end_date': '2025-08-05', 'duration': 25, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Pod Development', 'category': 'Growth', 'start_date': '2025-08-06', 'end_date': '2025-09-05', 'duration': 30, 'dependencies': '3', 'priority': 'normal'},
            {'id': '5', 'task_name': 'Maturation', 'category': 'Growth', 'start_date': '2025-09-06', 'end_date': '2025-09-25', 'duration': 19, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-09-26', 'end_date': '2025-10-05', 'duration': 9, 'dependencies': '5', 'priority': 'critical'}
        ],
        'onion': [
            {'id': '1', 'task_name': 'Nursery Preparation', 'category': 'Preparation', 'start_date': '2025-10-15', 'end_date': '2025-11-05', 'duration': 21, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Field Preparation', 'category': 'Preparation', 'start_date': '2025-11-06', 'end_date': '2025-11-15', 'duration': 9, 'dependencies': '1', 'priority': 'critical'},
            {'id': '3', 'task_name': 'Transplanting', 'category': 'Planting', 'start_date': '2025-11-16', 'end_date': '2025-12-01', 'duration': 15, 'dependencies': '2', 'priority': 'critical'},
            {'id': '4', 'task_name': 'Vegetative Growth', 'category': 'Growth', 'start_date': '2025-12-02', 'end_date': '2026-01-15', 'duration': 44, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Bulb Development', 'category': 'Growth', 'start_date': '2026-01-16', 'end_date': '2026-03-01', 'duration': 44, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting & Curing', 'category': 'Harvest', 'start_date': '2026-03-02', 'end_date': '2026-03-15', 'duration': 13, 'dependencies': '5', 'priority': 'critical'}
        ],
        'tomato': [
            {'id': '1', 'task_name': 'Nursery Preparation', 'category': 'Preparation', 'start_date': '2025-09-01', 'end_date': '2025-09-15', 'duration': 14, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Field Preparation', 'category': 'Preparation', 'start_date': '2025-09-16', 'end_date': '2025-09-25', 'duration': 9, 'dependencies': '1', 'priority': 'critical'},
            {'id': '3', 'task_name': 'Transplanting', 'category': 'Planting', 'start_date': '2025-09-26', 'end_date': '2025-10-05', 'duration': 9, 'dependencies': '2', 'priority': 'critical'},
            {'id': '4', 'task_name': 'Vegetative Growth', 'category': 'Growth', 'start_date': '2025-10-06', 'end_date': '2025-11-05', 'duration': 30, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Flowering & Fruiting', 'category': 'Growth', 'start_date': '2025-11-06', 'end_date': '2025-12-15', 'duration': 39, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2025-12-16', 'end_date': '2026-01-10', 'duration': 25, 'dependencies': '5', 'priority': 'critical'}
        ],
        'potato': [
            {'id': '1', 'task_name': 'Land Preparation', 'category': 'Preparation', 'start_date': '2025-10-15', 'end_date': '2025-10-25', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Seed Treatment & Planting', 'category': 'Planting', 'start_date': '2025-10-26', 'end_date': '2025-11-05', 'duration': 10, 'dependencies': '1', 'priority': 'critical'},
            {'id': '3', 'task_name': 'Germination & Early Growth', 'category': 'Growth', 'start_date': '2025-11-06', 'end_date': '2025-11-25', 'duration': 19, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Vegetative Growth & Earthing', 'category': 'Growth', 'start_date': '2025-11-26', 'end_date': '2025-12-25', 'duration': 29, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Tuber Development', 'category': 'Growth', 'start_date': '2025-12-26', 'end_date': '2026-01-25', 'duration': 30, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting', 'category': 'Harvest', 'start_date': '2026-01-26', 'end_date': '2026-02-05', 'duration': 10, 'dependencies': '5', 'priority': 'critical'}
        ],
        'garlic': [
            {'id': '1', 'task_name': 'Land Preparation', 'category': 'Preparation', 'start_date': '2025-10-10', 'end_date': '2025-10-20', 'duration': 10, 'dependencies': '', 'priority': 'critical'},
            {'id': '2', 'task_name': 'Clove Planting', 'category': 'Planting', 'start_date': '2025-10-21', 'end_date': '2025-11-01', 'duration': 11, 'dependencies': '1', 'priority': 'critical'},
            {'id': '3', 'task_name': 'Germination & Early Growth', 'category': 'Growth', 'start_date': '2025-11-02', 'end_date': '2025-12-01', 'duration': 29, 'dependencies': '2', 'priority': 'high'},
            {'id': '4', 'task_name': 'Vegetative Growth', 'category': 'Growth', 'start_date': '2025-12-02', 'end_date': '2026-01-15', 'duration': 44, 'dependencies': '3', 'priority': 'high'},
            {'id': '5', 'task_name': 'Bulb Development', 'category': 'Growth', 'start_date': '2026-01-16', 'end_date': '2026-02-25', 'duration': 40, 'dependencies': '4', 'priority': 'normal'},
            {'id': '6', 'task_name': 'Harvesting & Curing', 'category': 'Harvest', 'start_date': '2026-02-26', 'end_date': '2026-03-10', 'duration': 12, 'dependencies': '5', 'priority': 'critical'}
        ]
    }
    
    # Get base timeline or default to sugarcane
    timeline = base_timelines.get(crop_name, base_timelines['sugarcane']).copy()
    
    # Apply soil-based adjustments
    timeline = apply_soil_adjustments(timeline, soil_type, crop_name)
    
    return timeline

def get_location_soil_data(state, district, block, village):
    """
    Extract soil nutrient data from Excel file based on location
    """
    try:
        import pandas as pd
        excel_file = r"cropresults_with_state (1).xlsx"
        df = pd.read_excel(excel_file)
        
        # Clean column names (remove trailing spaces)
        df.columns = df.columns.str.strip()
        
        # Filter by location hierarchy (most specific to least specific)
        location_filter = df['STATE'] == state
        
        if district and district.strip():
            location_filter &= (df['DISTRICT NAME'] == district)
        if block and block.strip():
            location_filter &= (df['BLOCK NAME'] == block)
        if village and village.strip():
            location_filter &= (df['VILLAGE NAME'] == village)
        
        filtered_data = df[location_filter]
        
        if filtered_data.empty:
            print(f"⚠️  No data found for location: {state}, {district}, {block}, {village}")
            return None
        
        # Get the first matching record
        record = filtered_data.iloc[0]
        
        # Extract soil data in the same format as manual input
        location_soil_data = {
            'nitrogen': record.get('NITROGEN', ''),
            'phosphorus': record.get('PHOSPHORUS', ''),
            'potassium': record.get('POTASSIUM', ''),
            'organic_carbon': record.get('OC', ''),
            'ec': record.get('EC', ''),
            'ph': record.get('pH', ''),
            'copper': record.get('COPPER', ''),
            'boron': record.get('BORON', ''),
            'sulphur': record.get('SULPHUR', ''),
            'iron': record.get('IRON', ''),
            'zinc': record.get('ZINC', ''),
            'manganese': record.get('MANGANESE', ''),
            'temp_summer': record.get('SUMMER TEMPERATURE', ''),
            'temp_winter': record.get('WINTER TEMPERATURE', ''),
            'temp_monsoon': record.get('MONSOON TEMPERATURE', ''),
            'rainfall': record.get('Rainfall overall', ''),
            'location': f"{village}, {block}, {district}, {state}",
            'data_source': 'location_based',
            'timestamp': datetime.now().isoformat()
        }
        
        print(f"📍 Extracted soil data for: {location_soil_data['location']}")
        return location_soil_data
        
    except Exception as e:
        print(f"❌ Error extracting location soil data: {str(e)}")
        return None

def get_soil_type_from_analysis(soil_data):
    """
    Convert detailed soil analysis to simplified soil type classification
    """
    if not soil_data:
        return 'loamy'  # Default
    
    # Extract key indicators
    ph = soil_data.get('ph', '')
    ec = soil_data.get('ec', '')
    organic_carbon = soil_data.get('organic_carbon', '')
    
    # Classify based on analysis
    if 'Saline' in ec:
        return 'saline'
    elif 'Acidic' in ph:
        return 'acidic'
    elif 'Alkaline' in ph:
        return 'alkaline'
    elif 'High' in organic_carbon:
        return 'black_cotton'  # Rich organic content
    elif 'Low' in organic_carbon:
        return 'sandy'  # Poor organic content
    else:
        return 'loamy'  # Balanced conditions

def get_advanced_adjustments_from_analysis(soil_data, crop_type):
    """
    Generate advanced timeline adjustments based on detailed soil analysis
    """
    if not soil_data:
        return {}
    
    adjustments = {}
    
    # Nutrient-based adjustments
    if 'Low' in soil_data.get('nitrogen', ''):
        adjustments['extra_fertilization'] = {'duration': 7, 'phase': 'Nitrogen Supplementation'}
    
    if 'Low' in soil_data.get('phosphorus', ''):
        adjustments['phosphorus_treatment'] = {'duration': 5, 'phase': 'Phosphorus Application'}
    
    if 'Deficient' in soil_data.get('zinc', ''):
        adjustments['zinc_correction'] = {'duration': 3, 'phase': 'Zinc Foliar Spray'}
    
    if 'Deficient' in soil_data.get('boron', ''):
        adjustments['boron_treatment'] = {'duration': 3, 'phase': 'Boron Application'}
    
    # pH-based adjustments
    if 'Acidic' in soil_data.get('ph', ''):
        adjustments['liming'] = {'duration': 14, 'phase': 'Lime Application & Soil Conditioning'}
    
    # Temperature-based adjustments
    if 'High' in soil_data.get('temp_summer', '') and crop_type in ['cotton', 'rice']:
        adjustments['heat_protection'] = {'duration': 10, 'phase': 'Heat Stress Management'}
    
    # Rainfall-based adjustments
    if 'Low' in soil_data.get('rainfall', ''):
        adjustments['drought_prep'] = {'duration': 7, 'phase': 'Drought Preparedness & Mulching'}
    
    return adjustments

def apply_advanced_adjustments(timeline_data, advanced_adjustments):
    """
    Apply advanced adjustments based on detailed soil analysis
    """
    if not advanced_adjustments or not timeline_data.get('timeline'):
        return timeline_data
    
    timeline = timeline_data['timeline']
    modified_timeline = []
    current_date = datetime.strptime(timeline[0]['start_date'], '%Y-%m-%d')
    
    # Add advanced treatment phases at the beginning
    for adj_key, adj_data in advanced_adjustments.items():
        treatment_phase = {
            'id': f'ADV_{len(modified_timeline)+1}',
            'task_name': adj_data['phase'],
            'category': 'Advanced Treatment',
            'start_date': current_date.strftime('%Y-%m-%d'),
            'end_date': (current_date + timedelta(days=adj_data['duration'])).strftime('%Y-%m-%d'),
            'duration': adj_data['duration'],
            'dependencies': '',
            'priority': 'high'
        }
        modified_timeline.append(treatment_phase)
        current_date += timedelta(days=adj_data['duration'] + 1)
    
    # Add original timeline phases with updated dependencies
    for phase in timeline:
        new_phase = phase.copy()
        new_phase['start_date'] = current_date.strftime('%Y-%m-%d')
        
        # Update dependencies if we added treatment phases
        if modified_timeline and phase['dependencies'] == '':
            new_phase['dependencies'] = modified_timeline[-1]['id']
        
        new_phase['end_date'] = (current_date + timedelta(days=phase['duration'] - 1)).strftime('%Y-%m-%d')
        modified_timeline.append(new_phase)
        current_date += timedelta(days=phase['duration'] + 1)
    
    timeline_data['timeline'] = modified_timeline
    return timeline_data

def apply_soil_adjustments(timeline, soil_type, crop_name):
    """Apply comprehensive soil-crop specific dynamic adjustments to timeline"""
    
    # Comprehensive soil-crop compatibility matrix
    soil_crop_adjustments = {
        ('clayey_moist', 'rice'): {'growth_modifier': 1.3, 'irrigation_reduction': 0.7, 'disease_risk': 'low'},
        ('clayey_moist', 'sugarcane'): {'growth_modifier': 1.2, 'irrigation_reduction': 0.8, 'disease_risk': 'medium'},
        ('clayey_moist', 'wheat'): {'growth_modifier': 1.1, 'irrigation_reduction': 0.9, 'disease_risk': 'medium'},
        ('clayey_dry', 'cotton'): {'growth_modifier': 0.9, 'irrigation_increase': 1.4, 'disease_risk': 'low'},
        ('clayey_dry', 'jowar'): {'growth_modifier': 0.8, 'irrigation_increase': 1.3, 'disease_risk': 'high'},
        ('sandy_moist', 'groundnut'): {'growth_modifier': 1.2, 'fertilizer_increase': 1.3, 'disease_risk': 'low'},
        ('sandy_moist', 'tomato'): {'growth_modifier': 1.1, 'fertilizer_increase': 1.2, 'disease_risk': 'medium'},
        ('sandy_dry', 'jowar'): {'growth_modifier': 1.0, 'irrigation_increase': 1.6, 'disease_risk': 'low'},
        ('sandy_dry', 'groundnut'): {'growth_modifier': 0.9, 'irrigation_increase': 1.5, 'disease_risk': 'medium'},
        ('loamy_moist', 'wheat'): {'growth_modifier': 1.4, 'irrigation_reduction': 0.9, 'disease_risk': 'low'},
        ('loamy_moist', 'rice'): {'growth_modifier': 1.3, 'irrigation_reduction': 0.8, 'disease_risk': 'low'},
        ('loamy_moist', 'sugarcane'): {'growth_modifier': 1.5, 'irrigation_reduction': 0.8, 'disease_risk': 'low'},
        ('loamy_dry', 'cotton'): {'growth_modifier': 1.2, 'irrigation_increase': 1.1, 'disease_risk': 'low'},
        ('black_cotton', 'cotton'): {'growth_modifier': 1.6, 'irrigation_reduction': 0.7, 'disease_risk': 'low'},
        ('black_cotton', 'sugarcane'): {'growth_modifier': 1.4, 'irrigation_reduction': 0.8, 'disease_risk': 'low'},
        ('black_cotton', 'soyabean'): {'growth_modifier': 1.3, 'irrigation_reduction': 0.9, 'disease_risk': 'medium'},
        ('red_soil', 'groundnut'): {'growth_modifier': 1.1, 'fertilizer_increase': 1.2, 'disease_risk': 'medium'},
        ('red_soil', 'cotton'): {'growth_modifier': 1.0, 'fertilizer_increase': 1.1, 'disease_risk': 'medium'},
        ('alluvial', 'rice'): {'growth_modifier': 1.4, 'irrigation_reduction': 0.8, 'disease_risk': 'low'},
        ('alluvial', 'wheat'): {'growth_modifier': 1.3, 'irrigation_reduction': 0.9, 'disease_risk': 'low'},
        ('alluvial', 'sugarcane'): {'growth_modifier': 1.3, 'irrigation_reduction': 0.8, 'disease_risk': 'low'},
        ('laterite', 'rice'): {'growth_modifier': 0.7, 'fertilizer_increase': 1.8, 'disease_risk': 'high'},
        ('laterite', 'groundnut'): {'growth_modifier': 0.8, 'fertilizer_increase': 1.6, 'disease_risk': 'high'}
    }
    
    # Get specific adjustments for this soil-crop combination
    combination_key = (soil_type, crop_name)
    adjustments = soil_crop_adjustments.get(combination_key, {
        'growth_modifier': 1.0, 
        'irrigation_increase': 1.0, 
        'irrigation_reduction': 1.0,
        'fertilizer_increase': 1.0,
        'disease_risk': 'medium'
    })
    
    # Apply dynamic timeline modifications
    modified_timeline = []
    current_date = datetime.strptime(timeline[0]['start_date'], '%Y-%m-%d')
    
    # Add soil treatment phase for problematic soils
    if soil_type in ['sandy_dry', 'clayey_dry', 'laterite'] or adjustments.get('disease_risk') == 'high':
        treatment_duration = 5 if soil_type == 'laterite' else 3
        treatment_phase = {
            'id': 'T1',
            'task_name': f'Soil Amendment for {soil_type.replace("_", " ").title()}',
            'category': 'Treatment',
            'start_date': current_date.strftime('%Y-%m-%d'),
            'end_date': (current_date + timedelta(days=treatment_duration)).strftime('%Y-%m-%d'),
            'duration': treatment_duration,
            'dependencies': '',
            'priority': 'critical'
        }
        modified_timeline.append(treatment_phase)
        current_date += timedelta(days=treatment_duration + 1)
    
    # Process each phase with dynamic adjustments
    for i, phase in enumerate(timeline):
        new_phase = phase.copy()
        
        # Calculate new start date
        new_phase['start_date'] = current_date.strftime('%Y-%m-%d')
        
        # Apply duration modifications based on soil-crop compatibility
        original_duration = phase['duration']
        
        if 'Growth' in phase['category'] or 'growth' in phase['task_name'].lower():
            # Apply growth modifier
            growth_factor = adjustments.get('growth_modifier', 1.0)
            new_duration = max(1, int(original_duration * growth_factor))
        elif 'Irrigation' in phase['category'] or 'irrigation' in phase['task_name'].lower():
            # Apply irrigation adjustments
            if 'irrigation_increase' in adjustments:
                new_duration = int(original_duration * adjustments['irrigation_increase'])
            elif 'irrigation_reduction' in adjustments:
                new_duration = max(1, int(original_duration * adjustments['irrigation_reduction']))
            else:
                new_duration = original_duration
        elif 'Fertiliz' in phase['category'] or 'fertiliz' in phase['task_name'].lower():
            # Apply fertilizer adjustments
            if 'fertilizer_increase' in adjustments:
                new_duration = int(original_duration * adjustments['fertilizer_increase'])
                new_phase['task_name'] += f' (Extra for {soil_type.replace("_", " ").title()})'
            else:
                new_duration = original_duration
        else:
            new_duration = original_duration
        
        new_phase['duration'] = new_duration
        new_phase['end_date'] = (current_date + timedelta(days=new_duration - 1)).strftime('%Y-%m-%d')
        
        # Update dependencies for soil treatment
        if modified_timeline and phase['dependencies'] == '':
            new_phase['dependencies'] = 'T1'
        
        # Add disease management phases for high-risk combinations
        if adjustments.get('disease_risk') == 'high' and 'Growth' in phase['category']:
            disease_phase = {
                'id': f'D{i+1}',
                'task_name': f'Disease Monitoring & Control',
                'category': 'Disease Management',
                'start_date': (current_date + timedelta(days=new_duration//2)).strftime('%Y-%m-%d'),
                'end_date': (current_date + timedelta(days=new_duration//2 + 2)).strftime('%Y-%m-%d'),
                'duration': 3,
                'dependencies': new_phase['id'],
                'priority': 'high'
            }
            modified_timeline.append(disease_phase)
        
        modified_timeline.append(new_phase)
        current_date += timedelta(days=new_duration + 1)
    
    # Add extra irrigation phases for water-stressed soils
    if soil_type in ['sandy_dry', 'laterite'] and crop_name in ['rice', 'sugarcane']:
        extra_irrigation = {
            'id': 'EI1',
            'task_name': f'Additional Irrigation for {soil_type.replace("_", " ").title()}',
            'category': 'Extra Irrigation',
            'start_date': modified_timeline[-2]['end_date'],
            'end_date': (datetime.strptime(modified_timeline[-2]['end_date'], '%Y-%m-%d') + timedelta(days=5)).strftime('%Y-%m-%d'),
            'duration': 5,
            'dependencies': modified_timeline[-2]['id'],
            'priority': 'high'
        }
        modified_timeline.insert(-1, extra_irrigation)
    
    # Sort timeline by start date to ensure proper sequence
    modified_timeline.sort(key=lambda x: datetime.strptime(x['start_date'], '%Y-%m-%d'))
    
    return modified_timeline

def get_soil_type_advice(soil_type, crop_name):
    """Get soil-specific advice for the crop"""
    
    soil_advice = {
        'clayey_moist': {
            'description': 'Clay soil that retains water well',
            'advantages': ['Good water retention', 'High nutrient content', 'Rich in minerals'],
            'challenges': ['Poor drainage', 'Compaction issues', 'Slow to warm up'],
            'recommendations': ['Ensure proper drainage', 'Add organic matter', 'Avoid working when wet']
        },
        'clayey_dry': {
            'description': 'Clay soil that becomes hard when dry',
            'advantages': ['High nutrient retention', 'Good for deep-rooted crops'],
            'challenges': ['Hard when dry', 'Cracks formation', 'Poor water infiltration'],
            'recommendations': ['Improve soil structure with compost', 'Mulching is essential', 'Deep tillage before planting']
        },
        'sandy_moist': {
            'description': 'Sandy soil with good moisture',
            'advantages': ['Good drainage', 'Easy to work', 'Quick to warm up'],
            'challenges': ['Low water retention', 'Nutrient leaching', 'Low organic matter'],
            'recommendations': ['Frequent irrigation needed', 'Add organic matter regularly', 'Use slow-release fertilizers']
        },
        'sandy_dry': {
            'description': 'Very dry sandy soil',
            'advantages': ['No waterlogging', 'Good aeration'],
            'challenges': ['Very low water retention', 'High nutrient loss', 'Wind erosion'],
            'recommendations': ['Drip irrigation recommended', 'Heavy mulching', 'Frequent fertilizer application']
        },
        'loamy_moist': {
            'description': 'Ideal farming soil with good moisture',
            'advantages': ['Perfect balance of drainage and retention', 'High fertility', 'Easy to work'],
            'challenges': ['None major'],
            'recommendations': ['Maintain organic matter levels', 'Regular soil testing', 'Crop rotation']
        },
        'loamy_dry': {
            'description': 'Good farming soil but needs water management',
            'advantages': ['Good structure', 'Balanced nutrients', 'Versatile for many crops'],
            'challenges': ['Needs irrigation management'],
            'recommendations': ['Efficient irrigation system', 'Mulching', 'Organic matter addition']
        },
        'black_cotton': {
            'description': 'Rich, fertile black soil',
            'advantages': ['Very fertile', 'High water retention', 'Rich in nutrients'],
            'challenges': ['Waterlogging in monsoon', 'Sticky when wet'],
            'recommendations': ['Ensure drainage during monsoon', 'Perfect for cotton and sugarcane', 'Avoid cultivation when wet']
        },
        'red_soil': {
            'description': 'Common red-colored soil',
            'advantages': ['Good drainage', 'Easy to cultivate'],
            'challenges': ['Low fertility', 'Acidic nature', 'Iron deficiency common'],
            'recommendations': ['Lime application to reduce acidity', 'Regular organic matter addition', 'Iron supplementation']
        },
        'alluvial': {
            'description': 'River-deposited fertile soil',
            'advantages': ['Very fertile', 'Rich in minerals', 'Good water retention'],
            'challenges': ['Flooding risk', 'Variable composition'],
            'recommendations': ['Excellent for most crops', 'Manage flood risk', 'Regular soil testing']
        },
        'laterite': {
            'description': 'Iron-rich red clay soil',
            'advantages': ['Good for certain crops', 'Iron-rich'],
            'challenges': ['Poor fertility', 'Hard when dry', 'Acidic'],
            'recommendations': ['Heavy fertilization needed', 'Lime application essential', 'Organic matter critical']
        }
    }
    
    return soil_advice.get(soil_type, soil_advice['loamy_moist'])

@app.route('/dynamic-planner')
@require_login
def dynamic_planner():
    # Get URL parameter for pre-selected crop
    selected_crop = request.args.get('crop', '').lower()
    
    # Check if we have soil analysis data
    has_soil_analysis = session.get('has_soil_analysis', False)
    soil_data = session.get('soil_data', {})
    
    # If crop is selected and we have soil data, generate timeline directly
    if selected_crop and has_soil_analysis and soil_data:
        print(f"🚀 Direct Gantt generation for: {selected_crop}")
        
        # Generate timeline directly using stored soil data
        data_source = session.get('data_source', 'unknown')
        if data_source == 'location_based':
            soil_type = get_soil_type_from_analysis(soil_data)
        else:
            soil_type = get_soil_type_from_analysis(soil_data)
        
        # Generate comprehensive timeline
        timeline = generate_simple_crop_timeline(selected_crop, soil_type)
        
        # Apply advanced adjustments
        timeline_data = {'timeline': timeline}
        advanced_adjustments = get_advanced_adjustments_from_analysis(soil_data, selected_crop)
        if advanced_adjustments:
            timeline_data = apply_advanced_adjustments(timeline_data, advanced_adjustments)
            timeline = timeline_data['timeline']
        
        # Render direct result template
        return render_template('direct_gantt_result.html',
                             crop_name=selected_crop,
                             timeline=timeline,
                             soil_data=soil_data,
                             data_source=data_source,
                             total_phases=len(timeline),
                             estimated_duration=sum(phase.get('duration', 0) for phase in timeline))
    
    # Otherwise show the normal planner interface
    return render_template('dynamic_planner.html', 
                         selected_crop=selected_crop,
                         has_soil_analysis=has_soil_analysis,
                         soil_data=soil_data,
                         session=session)

@app.route('/generate-direct-timeline/<crop_name>')
@require_login
def generate_direct_timeline(crop_name):
    """Generate timeline directly for a specific crop using stored soil data"""
    try:
        # Check if we have soil analysis data
        soil_data = session.get('soil_data')
        has_detailed_analysis = session.get('has_soil_analysis', False)
        
        if not has_detailed_analysis or not soil_data:
            return jsonify({
                'error': 'No soil data available',
                'message': 'Please complete soil analysis first'
            }), 400
        
        # Get data source info
        data_source = session.get('data_source', 'manual')
        
        # Classify soil type from analysis
        soil_type = get_soil_type_from_analysis(soil_data)
        print(f"🌾 Direct generation: {crop_name} in {soil_type} soil ({data_source})")
        
        # Generate timeline
        timeline = generate_simple_crop_timeline(crop_name.lower(), soil_type)
        
        # Apply advanced adjustments
        timeline_data = {'timeline': timeline}
        advanced_adjustments = get_advanced_adjustments_from_analysis(soil_data, crop_name)
        if advanced_adjustments:
            print(f"🔧 Applying {len(advanced_adjustments)} advanced adjustments")
            timeline_data = apply_advanced_adjustments(timeline_data, advanced_adjustments)
            timeline = timeline_data['timeline']
        
        return jsonify({
            'success': True,
            'timeline': timeline,
            'crop_name': crop_name,
            'soil_type': soil_type,
            'data_source': data_source,
            'location': soil_data.get('location', 'Manual Analysis'),
            'total_phases': len(timeline),
            'estimated_duration': sum(phase.get('duration', 0) for phase in timeline),
            'analysis_date': soil_data.get('timestamp', 'Recent')
        })
        
    except Exception as e:
        print(f"❌ Error in direct timeline generation: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': 'Timeline generation failed',
            'message': str(e)
        }), 500

@app.route('/generate-dynamic-plan', methods=['POST'])
@require_login
def generate_dynamic_plan():
    """Generate dynamic crop timeline based on soil analysis or simple soil type"""
    try:
        # Handle both JSON and form data
        if request.is_json:
            data = request.get_json()
            crop_name = data.get('crop_name', '').lower()
            soil_type = data.get('soil_type', '')
        else:
            crop_name = request.form.get('crop_type', '').lower()
            soil_type = request.form.get('soil_type', '')
        
        # Check if we have detailed soil analysis from manual input
        soil_data = session.get('soil_data')
        has_detailed_analysis = session.get('has_soil_analysis', False)
        
        if has_detailed_analysis and soil_data:
            print(f"🔬 Using detailed soil analysis for {crop_name}")
            # Override soil_type with analysis-based classification
            analysis_soil_type = get_soil_type_from_analysis(soil_data)
            print(f"📊 Classified soil as: {analysis_soil_type} based on analysis")
            # Use the more specific classification
            final_soil_type = analysis_soil_type
            data_source = 'detailed_analysis'
        else:
            print(f"🌾 Using simple classification: {soil_type} soil + {crop_name}")
            final_soil_type = soil_type
            data_source = 'simple_classification'
        
        # Generate timeline using the comprehensive function
        timeline = generate_simple_crop_timeline(crop_name, final_soil_type)
        
        # Apply advanced adjustments if we have detailed analysis
        timeline_data = {'timeline': timeline}
        if has_detailed_analysis and soil_data:
            advanced_adjustments = get_advanced_adjustments_from_analysis(soil_data, crop_name)
            if advanced_adjustments:
                print(f"🔧 Applying {len(advanced_adjustments)} advanced adjustments")
                timeline_data = apply_advanced_adjustments(timeline_data, advanced_adjustments)
                timeline = timeline_data['timeline']
        
        # Get soil recommendations
        soil_advice = get_soil_type_advice(final_soil_type, crop_name)
        
        # Add detailed analysis info if available
        if has_detailed_analysis and soil_data:
            soil_advice += f"\n\n🔬 Based on your detailed soil analysis from {soil_data.get('timestamp', 'recent')}:"
            if 'Low' in soil_data.get('nitrogen', ''):
                soil_advice += "\n• Low nitrogen detected - additional fertilization phases added"
            if 'Deficient' in soil_data.get('zinc', ''):
                soil_advice += "\n• Zinc deficiency found - foliar spray treatment included"
            if 'Acidic' in soil_data.get('ph', ''):
                soil_advice += "\n• Acidic soil detected - lime application phase added"
        
        return jsonify({
            'success': True,
            'timeline': timeline,
            'soil_type': final_soil_type,
            'soil_advice': soil_advice,
            'crop_name': crop_name,
            'data_source': data_source,
            'analysis_date': soil_data.get('timestamp') if soil_data else None,
            'total_phases': len(timeline),
            'estimated_duration': sum(phase.get('duration', 0) for phase in timeline)
        })
        
    except Exception as e:
        print(f"❌ Error generating dynamic plan: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/village-data/<state>/<district>/<block>/<village>')
def village_data(state, district, block, village):
    row = df[
        (df['STATE'] == state) &
        (df['DISTRICT NAME'] == district) &
        (df['BLOCK NAME'] == block) &
        (df['VILLAGE NAME'] == village)
    ]

    if row.empty:
        return jsonify({'error': 'No data found'}), 404

    # Store location-based soil data in session
    location_soil_data = get_location_soil_data(state, district, block, village)
    if location_soil_data:
        session['soil_data'] = location_soil_data
        session['has_soil_analysis'] = True
        session['data_source'] = 'location_based'
        print(f"💾 Stored location-based soil data for: {village}, {district}, {state}")

    crop_columns = [
        'Sugarcane', 'Cotton', 'Soyabean', 'Rice', 'Jowar',
        'Tur (Pigeon Pea)', 'Wheat', 'Groundnut', 'Onion', 'Tomato',
        'Potato', 'Garlic'
    ]

    crop_data = {col: row.iloc[0][col] for col in crop_columns}
    
    # Add soil data availability info
    response_data = crop_data.copy()
    response_data['has_soil_data'] = location_soil_data is not None
    response_data['location'] = f"{village}, {block}, {district}, {state}"
    
    return jsonify(response_data)

@app.route('/market-prices')
def market_prices():
    state = request.args.get("state")
    mandi = request.args.get("mandi")
    crop = request.args.get("crop")

    if not state or not mandi or not crop:
        return jsonify({"error": "Missing required parameters"}), 400
    
    data = fetch_market_prices(state, mandi, crop)
    return jsonify(data)

@app.route('/market-dashboard')
@require_login
def market_dashboard():
    return render_template('market_dashboard.html')

@app.route('/compare')
@require_login
def compare():
    return render_template('compare.html')

@app.route('/guidance')
@require_login
def guidance():
    return render_template('guidance.html')

@app.route('/weather')
@require_login
def weather_page():
    """Render the weather dashboard page"""
    return render_template('weather.html')

@app.route('/weather', methods=['POST'])
@require_login
def weather_api():
    """API endpoint for weather data"""
    try:
        data = request.get_json()
        location = data.get('location', 'New Delhi')

        # OpenWeather API configuration
        API_KEY = '3f17cc8fc635e6b29600fb3de9e788fa'

        # Get coordinates for the location
        if ',' in location and location.replace(',', '').replace('.', '').replace('-', '').replace(' ', '').isdigit():
            # Location is coordinates (lat,lon)
            try:
                lat, lon = map(float, location.split(','))
            except:
                return jsonify({'error': 'Invalid coordinates format. Use: lat,lon'}), 400
        else:
            # Location is city name - get coordinates using geocoding
            geocoding_url = f"http://api.openweathermap.org/geo/1.0/direct?q={location}&limit=1&appid={API_KEY}"
            geo_response = requests.get(geocoding_url)
            geo_data = geo_response.json()

            if not geo_data:
                return jsonify({'error': f'Location "{location}" not found'}), 404

            lat = geo_data[0]['lat']
            lon = geo_data[0]['lon']
            location = f"{geo_data[0]['name']}, {geo_data[0].get('state', '')}, {geo_data[0]['country']}"

        # Get current weather
        current_url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API_KEY}&units=metric"
        current_response = requests.get(current_url)
        current_data = current_response.json()

        if current_response.status_code != 200:
            return jsonify({'error': 'Failed to fetch weather data'}), 500

        # Get 5-day forecast
        forecast_url = f"https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={API_KEY}&units=metric"
        forecast_response = requests.get(forecast_url)
        forecast_data = forecast_response.json()

        # Process current weather
        current_weather = {
            'temp': current_data['main']['temp'],
            'feels_like': current_data['main']['feels_like'],
            'description': current_data['weather'][0]['description'],
            'icon': current_data['weather'][0]['icon'],
            'humidity': current_data['main']['humidity'],
            'pressure': current_data['main']['pressure'],
            'wind_speed': round(current_data['wind']['speed'] * 3.6, 1),  # Convert m/s to km/h
            'visibility': round(current_data.get('visibility', 0) / 1000, 1),  # Convert to km
            'clouds': current_data['clouds']['all'],
            'sunrise': datetime.fromtimestamp(current_data['sys']['sunrise']).strftime('%H:%M'),
            'sunset': datetime.fromtimestamp(current_data['sys']['sunset']).strftime('%H:%M'),
            'location': location
        }

        # Get UV Index from One Call API
        try:
            onecall_url = f"https://api.openweathermap.org/data/2.5/onecall?lat={lat}&lon={lon}&appid={API_KEY}&units=metric"
            onecall_response = requests.get(onecall_url)
            if onecall_response.status_code == 200:
                onecall_data = onecall_response.json()
                current_weather['uv_index'] = round(onecall_data['current'].get('uvi', 0), 1)
            else:
                current_weather['uv_index'] = 'N/A'
        except:
            current_weather['uv_index'] = 'N/A'

        # Process 5-day forecast
        forecast_list = []
        processed_dates = set()

        for item in forecast_data['list']:
            date = datetime.fromtimestamp(item['dt']).date()
            if date not in processed_dates and len(forecast_list) < 5:
                day_name = datetime.fromtimestamp(item['dt']).strftime('%A')
                if date == datetime.now().date():
                    day_name = 'Today'
                elif date == (datetime.now() + timedelta(days=1)).date():
                    day_name = 'Tomorrow'

                forecast_list.append({
                    'day': day_name,
                    'temp_max': item['main']['temp_max'],
                    'temp_min': item['main']['temp_min'],
                    'description': item['weather'][0]['description'],
                    'icon': item['weather'][0]['icon']
                })
                processed_dates.add(date)

        # Generate weather alerts
        alerts = generate_weather_alerts(current_data, forecast_data)

        return jsonify({
            'current': current_weather,
            'forecast': forecast_list,
            'alerts': alerts
        })

    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

def generate_weather_alerts(current_data, forecast_data):
    """Generate extreme weather alerts for farmers"""
    alerts = []

    # Current weather alerts
    temp = current_data['main']['temp']
    humidity = current_data['main']['humidity']
    wind_speed = current_data['wind']['speed'] * 3.6  # Convert to km/h
    weather_main = current_data['weather'][0]['main'].lower()

    # Extreme temperature alerts
    if temp > 40:
        alerts.append({
            'severity': 'severe',
            'title': 'Extreme Heat Warning',
            'description': f'Temperature is {temp:.1f}°C. Protect crops from heat stress. Increase irrigation and provide shade for livestock.'
        })
    elif temp > 35:
        alerts.append({
            'severity': 'warning',
            'title': 'High Temperature Alert',
            'description': f'Temperature is {temp:.1f}°C. Monitor crops for heat stress. Consider early morning irrigation.'
        })
    elif temp < 0:
        alerts.append({
            'severity': 'severe',
            'title': 'Frost Warning',
            'description': f'Temperature is {temp:.1f}°C. Protect sensitive crops from frost damage. Cover plants or use frost protection methods.'
        })
    elif temp < 5:
        alerts.append({
            'severity': 'warning',
            'title': 'Cold Weather Alert',
            'description': f'Temperature is {temp:.1f}°C. Cold-sensitive crops may be affected. Take protective measures.'
        })

    # High humidity alert
    if humidity > 80 and temp > 25:
        alerts.append({
            'severity': 'warning',
            'title': 'High Humidity Alert',
            'description': f'Humidity is {humidity}%. Risk of fungal diseases. Ensure good air circulation and consider fungicide application.'
        })

    # Wind alerts
    if wind_speed > 50:
        alerts.append({
            'severity': 'severe',
            'title': 'Strong Wind Warning',
            'description': f'Wind speed is {wind_speed:.1f} km/h. Secure equipment and protect tall crops. Avoid spraying activities.'
        })
    elif wind_speed > 30:
        alerts.append({
            'severity': 'warning',
            'title': 'Windy Conditions',
            'description': f'Wind speed is {wind_speed:.1f} km/h. Be cautious with spraying and protect young plants.'
        })

    # Precipitation alerts
    if 'rain' in weather_main or 'drizzle' in weather_main:
        alerts.append({
            'severity': 'info',
            'title': 'Rain Expected',
            'description': 'Rain is forecasted. Postpone irrigation and outdoor activities. Good for rain-fed crops.'
        })

    if 'thunderstorm' in weather_main:
        alerts.append({
            'severity': 'severe',
            'title': 'Thunderstorm Warning',
            'description': 'Thunderstorms expected. Avoid outdoor work and protect livestock. Risk of hail damage.'
        })

    # Check forecast for upcoming severe weather
    for item in forecast_data['list'][:8]:  # Check next 24 hours
        item_temp = item['main']['temp']
        item_weather = item['weather'][0]['main'].lower()
        item_wind = item['wind']['speed'] * 3.6

        forecast_time = datetime.fromtimestamp(item['dt']).strftime('%H:%M')

        if 'thunderstorm' in item_weather:
            alerts.append({
                'severity': 'warning',
                'title': f'Thunderstorm Expected at {forecast_time}',
                'description': 'Plan indoor activities. Secure farm equipment and protect livestock.'
            })

        if item_temp > 42:
            alerts.append({
                'severity': 'severe',
                'title': f'Extreme Heat Expected at {forecast_time}',
                'description': f'Temperature will reach {item_temp:.1f}°C. Prepare cooling measures for crops and animals.'
            })

    return alerts

@app.route('/disease-detection')
@require_login
def disease_detection():
    """Render the crop disease detection page"""
    return render_template('disease_detection.html')

@app.route('/analyze-disease', methods=['POST'])
@require_login
def analyze_disease():
    """API endpoint for crop disease analysis"""
    try:
        # Check if image was uploaded
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No image selected'}), 400

        # Validate file type
        allowed_extensions = {'png', 'jpg', 'jpeg', 'webp'}
        if not file.filename.lower().endswith(tuple(allowed_extensions)):
            return jsonify({'error': 'Invalid file type. Please upload PNG, JPG, or WEBP images'}), 400

        # For now, return simulated results
        # In production, this would integrate with an AI model for disease detection
        results = {
            'crop_type': 'Tomato',
            'disease': 'Late Blight',
            'confidence': 87.5,
            'severity': 'Moderate',
            'healthy': False,
            'recommendations': [
                'Apply copper-based fungicide immediately',
                'Remove affected leaves and dispose properly',
                'Improve air circulation around plants',
                'Reduce overhead watering',
                'Monitor plants daily for spread',
                'Consider resistant varieties for next planting'
            ],
            'prevention_tips': [
                'Use drip irrigation instead of overhead spraying',
                'Ensure proper plant spacing for air circulation',
                'Apply preventive fungicide during humid conditions',
                'Remove plant debris regularly'
            ]
        }

        return jsonify(results)

    except Exception as e:
        return jsonify({'error': f'Analysis failed: {str(e)}'}), 500

# ---------------------------
# Feedback Routes (NEW)
# ---------------------------

@app.route('/feedback', methods=['GET'])
@require_login
def feedback_page():
    """Render the feedback page"""
    return render_template('feedback.html')

@app.route('/submit_feedback', methods=['POST'])
@require_login
def submit_feedback():
    """Handle feedback form submission"""
    name = request.form.get("name", "").strip()
    email = request.form.get("email", "").strip()
    feedback_text = request.form.get("feedback", "").strip()

    if not feedback_text:
        return jsonify({"status": "error", "message": "Feedback is required"}), 400

    feedback_entry = {
        "name": name,
        "email": email,
        "feedback": feedback_text
    }

    try:
        save_feedback_to_json(feedback_entry)
        return jsonify({"status": "ok", "message": "Thank you for your feedback!"})
    except Exception as e:
        return jsonify({"status": "error", "message": f"Failed to save feedback: {e}"}), 500

# ---------------------------
# Chatbot Routes
# ---------------------------

@app.route("/chat", methods=["POST"])
@require_login
def chat():
    body = request.get_json(force=True)
    message = body.get("message", "")
    if not message:
        return jsonify({"error": "empty message"}), 400

    tone = body.get("tone", "farmer")
    messages = compose_prompt(message, tone=tone)
    assistant_text = call_llm(messages)

    return jsonify({
        "answer": assistant_text,
        "sources": []  # No local sources, pure LLM-based
    })

# ---------------------------
# Static File Serving
# ---------------------------

@app.route("/static/<path:p>")
def static_files(p):
    return send_from_directory("static", p)

@app.route("/test_page.html")
def test_page():
    return send_from_directory("", "test_page.html")

# ---------------------------
# Maharashtra Location Data API Endpoints
# ---------------------------

@app.route('/api/maharashtra/districts')
def get_maharashtra_districts():
    """Get all districts in Maharashtra from Excel"""
    try:
        df = pd.read_excel('cropresults_with_state (1).xlsx')
        # Clean district names and remove NaN
        districts = df['DISTRICT NAME '].dropna().str.strip().unique()
        districts = [d for d in districts if pd.notna(d) and d != '']
        districts.sort()
        return jsonify({'status': 'success', 'districts': districts})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/maharashtra/blocks/<district>')
def get_maharashtra_blocks(district):
    """Get blocks for a specific district in Maharashtra"""
    try:
        df = pd.read_excel('cropresults_with_state (1).xlsx')
        # Filter by district and get blocks
        district_data = df[df['DISTRICT NAME '].str.strip() == district]
        blocks = district_data['BLOCK NAME '].dropna().str.strip().unique()
        blocks = [b for b in blocks if pd.notna(b) and b != '']
        blocks.sort()
        return jsonify({'status': 'success', 'blocks': blocks})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/maharashtra/villages/<district>/<block>')
def get_maharashtra_villages(district, block):
    """Get villages for a specific district and block in Maharashtra"""
    try:
        df = pd.read_excel('cropresults_with_state (1).xlsx')
        # Filter by district and block
        filtered_data = df[
            (df['DISTRICT NAME '].str.strip() == district) & 
            (df['BLOCK NAME '].str.strip() == block)
        ]
        villages = filtered_data['VILLAGE NAME '].dropna().str.strip().unique()
        villages = [v for v in villages if pd.notna(v) and v != '']
        villages.sort()
        return jsonify({'status': 'success', 'villages': villages})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/maharashtra/crops')
def get_maharashtra_crops():
    """Get all available crops from Excel data"""
    try:
        # Get crop columns from Excel
        crop_columns = ['Sugarcane', 'Cotton', 'Soyabean', 'Rice', 'Jowar', 
                       'Tur (Pigeon Pea)', 'Wheat', 'Groundnut', 'Onion', 
                       'Tomato', 'Potato', 'Garlic']
        
        # Create crop options with display names and values
        crops = []
        for crop in crop_columns:
            # Create value (lowercase, no spaces) and display name
            value = crop.lower().replace(' ', '').replace('(', '').replace(')', '')
            if 'pigeon' in value:
                value = 'tur'
            crops.append({
                'value': value,
                'display': crop,
                'column': crop
            })
        
        return jsonify({'status': 'success', 'crops': crops})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/maharashtra/location-suitability/<district>/<block>/<village>/<crop>')
def get_location_crop_suitability(district, block, village, crop):
    """Get crop suitability for specific location"""
    try:
        df = pd.read_excel('cropresults_with_state (1).xlsx')
        
        # Find the crop column name
        crop_column_map = {
            'sugarcane': 'Sugarcane',
            'cotton': 'Cotton', 
            'soyabean': 'Soyabean',
            'rice': 'Rice',
            'jowar': 'Jowar',
            'tur': 'Tur (Pigeon Pea)',
            'wheat': 'Wheat',
            'groundnut': 'Groundnut',
            'onion': 'Onion',
            'tomato': 'Tomato',
            'potato': 'Potato',
            'garlic': 'Garlic'
        }
        
        crop_column = crop_column_map.get(crop)
        if not crop_column:
            return jsonify({'status': 'error', 'message': 'Invalid crop type'})
        
        # Filter data for specific location
        location_data = df[
            (df['DISTRICT NAME '].str.strip() == district) & 
            (df['BLOCK NAME '].str.strip() == block) &
            (df['VILLAGE NAME '].str.strip() == village)
        ]
        
        if location_data.empty:
            return jsonify({'status': 'error', 'message': 'Location not found'})
        
        # Get suitability and soil data
        suitability = location_data[crop_column].iloc[0] if not location_data[crop_column].empty else 'Not Available'
        
        # Get soil parameters
        soil_data = {
            'nitrogen': float(location_data['NITROGEN'].iloc[0]) if pd.notna(location_data['NITROGEN'].iloc[0]) else 0,
            'phosphorus': float(location_data['PHOSPHORUS'].iloc[0]) if pd.notna(location_data['PHOSPHORUS'].iloc[0]) else 0,
            'potassium': float(location_data['POTASSIUM'].iloc[0]) if pd.notna(location_data['POTASSIUM'].iloc[0]) else 0,
            'ph': float(location_data['pH'].iloc[0]) if pd.notna(location_data['pH'].iloc[0]) else 7.0,
            'organic_carbon': float(location_data['OC'].iloc[0]) if pd.notna(location_data['OC'].iloc[0]) else 0,
            'ec': float(location_data['EC'].iloc[0]) if pd.notna(location_data['EC'].iloc[0]) else 0
        }
        
        return jsonify({
            'status': 'success',
            'suitability': suitability,
            'soil_data': soil_data,
            'location': {
                'district': district,
                'block': block,
                'village': village
            }
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

# ---------------------------
# Run the Server
# ---------------------------

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
