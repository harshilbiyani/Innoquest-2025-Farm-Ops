from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
import random
import requests
from crop_recommendation import CropRecommendationService
from crop_growth_service import CropGrowthService
import re
import google.generativeai as genai

# Load environment variables from .env file
load_dotenv()

# Configure Google Gemini AI
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
USE_AI_CHATBOT = bool(GEMINI_API_KEY)  # Use AI if API key is available

if USE_AI_CHATBOT:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        print("✅ Google Gemini AI configured successfully")
    except Exception as e:
        print(f"⚠️ Failed to configure Gemini AI: {e}")
        USE_AI_CHATBOT = False
else:
    print("ℹ️ No GEMINI_API_KEY found - using rule-based chatbot")

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# MongoDB Configuration
MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
DB_NAME = os.getenv('DB_NAME', 'farmops_db')
COLLECTION_NAME = os.getenv('COLLECTION_NAME', 'users')

# Initialize MongoDB client
try:
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    users_collection = db[COLLECTION_NAME]
    print(f"✓ Connected to MongoDB: {DB_NAME}")
except Exception as e:
    print(f"✗ Error connecting to MongoDB: {e}")

# Initialize Crop Recommendation Service
excel_path = os.getenv('CROP_DATA_PATH', 'cropresults_with_state (1).xlsx')
crop_service = CropRecommendationService(excel_path=excel_path)

# ==================== AGRICULTURAL CHATBOT ====================
class AgriculturalChatbot:
    """Advanced agricultural chatbot with AI integration and fallback logic"""
    
    def __init__(self, use_ai=False):
        self.use_ai = use_ai
        self.conversation_history = {}  # Store history per user_id
        self.gemini_api_key = GEMINI_API_KEY if use_ai else None
        
        # System prompt for AI
        self.system_prompt = """You are an expert agricultural advisor helping farmers with crop selection, disease management, soil health, irrigation, weather decisions, market prices, and government schemes. Provide practical advice specific to Indian agriculture. Keep responses concise (2-3 paragraphs), use bullet points, and include emojis. Suggest organic alternatives when mentioning chemicals."""
        
        if self.use_ai:
            print("✅ AI Chatbot initialized with Gemini REST API")
        else:
            print("ℹ️  Rule-based chatbot initialized")
        
        # Comprehensive agricultural knowledge base
        self.agriculture_knowledge = {
            "crop_diseases": {
                "wheat": {
                    "rust": "Apply fungicides like propiconazole. Use resistant varieties and maintain proper crop rotation.",
                    "blight": "Use certified disease-free seeds, apply copper-based fungicides, ensure proper drainage.",
                    "smut": "Treat seeds with hot water or fungicides like carboxin. Plant resistant varieties."
                },
                "rice": {
                    "blast": "Use resistant varieties, apply tricyclazole fungicides, maintain proper water levels.",
                    "sheath_blight": "Control with proper water management and apply fungicides when necessary.",
                    "bacterial_leaf_blight": "Use certified seeds and apply copper-based bactericides."
                },
                "tomato": {
                    "blight": "Use drip irrigation, apply copper fungicides, ensure good air circulation.",
                    "wilt": "Improve soil drainage, use resistant varieties, avoid overwatering.",
                    "mosaic_virus": "Control aphid populations, use virus-free seeds, remove weeds."
                },
                "cotton": {
                    "bollworm": "Use Bt cotton varieties, apply neem-based pesticides, practice crop rotation.",
                    "wilt": "Use resistant varieties, improve soil drainage, avoid waterlogging.",
                    "leaf_curl": "Control whitefly populations, use virus-free seeds, remove infected plants."
                },
                "maize": {
                    "blight": "Use resistant varieties, ensure proper spacing for air circulation, apply fungicides.",
                    "rust": "Apply fungicides early, use resistant varieties, remove infected leaves.",
                    "stem_borer": "Use pheromone traps, apply biological pesticides, practice clean cultivation."
                }
            }
        }
        
        self.greeting_responses = [
            "Hello! I'm AgroBot, your agricultural assistant. How can I help you with your farming needs today?",
            "Welcome to FarmOps AI! I'm here to help you with all your agricultural questions.",
            "Greetings, farmer friend! I'm ready to assist you with crop management, pest control, or any farming query.",
            "Hello! I'm your farming companion, ready to provide solutions for all your agricultural challenges."
        ]
    
    def process_message(self, message, user_id="default"):
        """Process user message and maintain conversation history"""
        message_lower = message.lower().strip()
        
        print(f"📨 Processing message from user '{user_id}': {message}")
        print(f"🔧 AI Mode: {'ENABLED' if self.use_ai else 'DISABLED (using rule-based)'}")
        
        # Initialize conversation history for new users
        if user_id not in self.conversation_history:
            self.conversation_history[user_id] = []
        
        # Store conversation history (keep last 10 exchanges per user)
        self.conversation_history[user_id].append({
            'user': message,
            'timestamp': datetime.utcnow(),
        })
        
        # Limit conversation history to avoid memory issues
        if len(self.conversation_history[user_id]) > 20:
            self.conversation_history[user_id] = self.conversation_history[user_id][-20:]
        
        # Generate response using AI or fallback
        if self.use_ai:
            response = self.generate_ai_response(message, user_id)
        else:
            response = self.generate_response(message_lower, message)
        
        # Store bot response
        self.conversation_history[user_id].append({
            'bot': response,
            'timestamp': datetime.utcnow(),
        })
        
        return response
    
    def generate_ai_response(self, message, user_id="default"):
        """Generate response using Google Gemini AI via REST API"""
        try:
            print(f"🤖 Using AI to generate response for: {message[:50]}...")
            
            # Get recent conversation context for this specific user
            recent_history = []
            if user_id in self.conversation_history:
                user_messages = self.conversation_history[user_id][-6:]  # Last 3 exchanges
                
                for entry in user_messages:
                    if 'user' in entry:
                        recent_history.append(f"User: {entry['user']}")
                    if 'bot' in entry:
                        # Truncate long responses in context
                        bot_msg = entry['bot'][:200] + "..." if len(entry['bot']) > 200 else entry['bot']
                        recent_history.append(f"Assistant: {bot_msg}")
            
            context = "\n".join(recent_history) if recent_history else "No previous conversation"
            
            # Create prompt with context
            full_prompt = f"""{self.system_prompt}

Previous conversation:
{context}

Current user question: {message}

Provide a helpful, practical response:"""
            
            print(f"📝 Sending request to Gemini API...")
            
            # Check if API key is available
            if not self.gemini_api_key or self.gemini_api_key == '':
                print("❌ No Gemini API key found!")
                print("💡 Set GEMINI_API_KEY in your .env file to enable AI chatbot")
                raise Exception("No API key configured")
            
            # Try both v1 and v1beta endpoints with multiple model names
            api_configs = [
                # Latest API (v1) - Recommended
                {'version': 'v1', 'model': 'gemini-1.5-flash-latest'},
                {'version': 'v1', 'model': 'gemini-1.5-pro-latest'},
                {'version': 'v1', 'model': 'gemini-1.5-flash'},
                {'version': 'v1', 'model': 'gemini-1.5-pro'},
                # Beta API (v1beta) - Fallback
                {'version': 'v1beta', 'model': 'gemini-1.5-flash'},
                {'version': 'v1beta', 'model': 'gemini-1.5-pro'},
                {'version': 'v1beta', 'model': 'gemini-pro'},
                # Legacy names
                {'version': 'v1', 'model': 'gemini-pro'},
            ]
            
            last_error = None
            for config in api_configs:
                try:
                    api_version = config['version']
                    model_name = config['model']
                    
                    # Use the API endpoint
                    url = f"https://generativelanguage.googleapis.com/{api_version}/models/{model_name}:generateContent?key={self.gemini_api_key}"
                    
                    payload = {
                        "contents": [{
                            "parts": [{"text": full_prompt}]
                        }],
                        "generationConfig": {
                            "temperature": 0.7,
                            "maxOutputTokens": 500,
                        }
                    }
                    
                    print(f"🔄 Trying {api_version}/{model_name}...")
                    response = requests.post(url, json=payload, timeout=30)
                    
                    if response.status_code == 200:
                        data = response.json()
                        
                        # Validate response structure
                        if 'candidates' in data and len(data['candidates']) > 0:
                            candidate = data['candidates'][0]
                            if 'content' in candidate and 'parts' in candidate['content']:
                                ai_response = candidate['content']['parts'][0]['text'].strip()
                                print(f"✅ AI response generated successfully using {api_version}/{model_name}!")
                                print(f"📝 Response preview: {ai_response[:100]}...")
                                return ai_response
                        
                        print(f"⚠️ Unexpected response structure from {model_name}")
                        print(f"📄 Response data: {str(data)[:200]}")
                        last_error = f"Unexpected response structure"
                        continue
                        
                    elif response.status_code == 404:
                        print(f"⚠️ Model {api_version}/{model_name} not available (404)")
                        last_error = f"Model not available: {model_name}"
                        continue
                    elif response.status_code == 400:
                        error_data = response.json() if response.headers.get('content-type') == 'application/json' else {}
                        error_msg = error_data.get('error', {}).get('message', response.text[:200])
                        print(f"❌ Bad request for {model_name}: {error_msg}")
                        last_error = f"Bad request: {error_msg}"
                        continue
                    elif response.status_code == 403:
                        print(f"🔒 API key invalid or quota exceeded (403)")
                        last_error = "API key issue or quota exceeded"
                        # Don't continue trying if API key is invalid
                        break
                    else:
                        error_msg = response.text[:300]
                        print(f"❌ Error for {model_name} ({response.status_code}): {error_msg}")
                        last_error = f"API error {response.status_code}"
                        continue
                        
                except requests.exceptions.Timeout:
                    print(f"⏱️ Timeout with {model_name}, trying next...")
                    last_error = "Request timeout"
                    continue
                except Exception as e:
                    print(f"⚠️ Exception with {model_name}: {type(e).__name__}: {str(e)[:100]}")
                    last_error = str(e)
                    continue
            
            # If all models failed, raise exception with last error
            raise Exception(f"All Gemini models failed. Last error: {last_error}")
            
        except Exception as e:
            print(f"❌ AI generation error: {type(e).__name__}: {e}")
            # Fallback to rule-based response
            print("⚠️ Falling back to rule-based response")
            return self.generate_response(message.lower(), message)
    
    def generate_response(self, message_lower, original_message):
        """Generate intelligent response based on message content"""
        
        # Greeting detection
        greeting_words = ['hello', 'hi', 'hey', 'greetings', 'good morning', 'good afternoon', 'good evening', 'namaste']
        if any(word in message_lower for word in greeting_words):
            return random.choice(self.greeting_responses)
        
        # Thank you responses
        if any(word in message_lower for word in ['thank', 'thanks', 'धन्यवाद']):
            return "You're welcome! Feel free to ask me anything about farming. Happy farming! 🌾"
        
        # Help queries
        if any(word in message_lower for word in ['help', 'assist', 'guide', 'what can you do']):
            return self.provide_help()
        
        # Specific crop information queries (detect crop mentions)
        crop_keywords = {
            'tomato': self.handle_tomato_query,
            'wheat': self.handle_wheat_query,
            'rice': self.handle_rice_query,
            'cotton': self.handle_cotton_query,
            'maize': self.handle_maize_query,
        }
        
        for crop, handler in crop_keywords.items():
            if crop in message_lower:
                # If asking about diseases specifically
                if any(word in message_lower for word in ['disease', 'pest', 'problem', 'infected']):
                    return self.handle_disease_query(message_lower)
                # General crop information
                return handler()
        
        # Disease queries
        if any(word in message_lower for word in ['disease', 'pest', 'problem', 'infected', 'sick', 'damage', 'attack']):
            return self.handle_disease_query(message_lower)
        
        # Fertilizer queries
        if any(word in message_lower for word in ['fertilizer', 'nutrient', 'manure', 'compost', 'npk', 'nitrogen', 'phosphorus', 'potassium']):
            return self.handle_fertilizer_query(message_lower)
        
        # Weather queries
        if any(word in message_lower for word in ['weather', 'rain', 'temperature', 'climate', 'monsoon', 'season']):
            return self.handle_weather_query()
        
        # Crop selection queries
        if any(word in message_lower for word in ['crop', 'plant', 'grow', 'cultivation', 'which crop', 'what crop']):
            return self.handle_crop_query()
        
        # Water/irrigation queries
        if any(word in message_lower for word in ['water', 'irrigation', 'drip', 'sprinkler', 'drought']):
            return self.handle_water_query()
        
        # Market/price queries
        if any(word in message_lower for word in ['price', 'market', 'sell', 'mandi', 'profit', 'cost']):
            return self.handle_market_query()
        
        # Government schemes
        if any(word in message_lower for word in ['scheme', 'subsidy', 'government', 'loan', 'insurance', 'pm-kisan']):
            return self.handle_schemes_query()
        
        # Default response
        return "I understand you're asking about farming. I can help with crop diseases, fertilizers, weather advice, irrigation, market prices, government schemes, and general farming guidance. Could you please be more specific about what you'd like to know?"
    
    def provide_help(self):
        """Provide comprehensive help information"""
        return """I can help you with:

🌾 Crop disease identification and treatment
🧪 Fertilizer recommendations and soil management  
🌤️ Weather-related farming decisions
🐛 Pest control strategies
🌱 Crop selection and planting advice
💧 Irrigation and water management
📅 Seasonal farming guidance
💰 Market prices and profit planning
📋 Government schemes and subsidies

What specific farming challenge can I help you with today?"""
    
    def handle_disease_query(self, message):
        """Handle disease-related queries with specific crop information"""
        # Detect crop type
        crop_mentioned = None
        for crop in self.agriculture_knowledge["crop_diseases"]:
            if crop in message:
                crop_mentioned = crop
                break
        
        if crop_mentioned:
            diseases = self.agriculture_knowledge["crop_diseases"][crop_mentioned]
            response = f"Common {crop_mentioned} diseases and treatments:\n\n"
            for disease, treatment in diseases.items():
                response += f"🦠 **{disease.replace('_', ' ').title()}**: {treatment}\n\n"
            return response
        else:
            return """For disease management, I need to know which crop you're growing. I can help with:

🌾 Wheat diseases (rust, blight, smut)
🍚 Rice diseases (blast, sheath blight, bacterial leaf blight)  
🍅 Tomato diseases (blight, wilt, mosaic virus)
🌿 Cotton diseases (bollworm, wilt, leaf curl)
🌽 Maize diseases (blight, rust, stem borer)

Please specify your crop and describe the symptoms you're seeing."""
    
    def handle_fertilizer_query(self, message):
        """Provide fertilizer recommendations"""
        return """Here's comprehensive fertilizer guidance:

🧪 **Soil Testing First**: Always test your soil to know exact nutrient needs

🌱 **NPK Basics**:
• Nitrogen (N): Promotes leaf growth and green color
• Phosphorus (P): Strengthens roots and flowering  
• Potassium (K): Improves disease resistance and fruit quality

🍂 **Organic Options**:
• Compost: Improves soil structure and provides slow-release nutrients
• Farmyard Manure: Rich in organic matter and essential nutrients
• Vermicompost: High-quality organic fertilizer with beneficial microbes
• Green manure: Legumes that fix nitrogen naturally

⏰ **Application Timing**: 
• Basal dose: Before planting
• Top dressing: During active growth phases
• Foliar spray: For quick nutrient correction

What specific crop are you growing? I can provide more targeted fertilizer recommendations."""
    
    def handle_weather_query(self):
        """Provide weather-related farming advice"""
        return """Weather plays a crucial role in farming success:

🌤️ **Weather Monitoring**: 
• Check daily forecasts for planning field operations
• Monitor rainfall patterns for irrigation decisions
• Watch temperature trends for pest and disease risks

☔ **Rainfall Management**:
• Prepare drainage for heavy rain periods
• Plan water conservation during dry spells
• Adjust planting dates based on monsoon predictions

🌡️ **Temperature Considerations**:
• Protect crops from extreme temperatures
• Time planting to avoid heat stress
• Plan harvesting around weather windows

🌪️ **Extreme Weather Protection**:
• Use mulching to moderate soil temperature
• Install windbreaks for cyclone-prone areas
• Have contingency plans for frost or hailstorms

Would you like specific advice for current weather conditions in your area?"""
    
    def handle_crop_query(self):
        """Provide crop selection advice"""
        return """Choosing the right crop is essential for success:

🌾 **Crop Selection Factors**:
• Soil type and pH
• Climate and rainfall patterns
• Water availability
• Market demand and prices
• Your experience and resources

🌱 **Major Crop Categories**:
• **Kharif (Monsoon)**: Rice, maize, cotton, soybean, groundnut
• **Rabi (Winter)**: Wheat, mustard, chickpea, barley, peas
• **Zaid (Summer)**: Vegetables, watermelon, cucumber, fodder crops

💡 **Tips for Success**:
• Start with crops you're familiar with
• Consider crop rotation for soil health
• Check government MSP (Minimum Support Price) crops
• Evaluate market demand in your area

Use our Crop Recommendation feature in the app for personalized suggestions based on your soil and location!"""
    
    def handle_water_query(self):
        """Provide irrigation and water management advice"""
        return """Efficient water management is critical for farming:

💧 **Irrigation Methods**:
• **Drip Irrigation**: 60% water savings, best for vegetables, fruits
• **Sprinkler**: Good for field crops, saves 30-40% water
• **Flood/Furrow**: Traditional method, higher water use
• **Micro-sprinkler**: Ideal for orchards and plantations

⏰ **Irrigation Scheduling**:
• Morning or evening watering to reduce evaporation
• Check soil moisture before irrigating
• Adjust frequency based on crop growth stage

🌧️ **Water Conservation**:
• Mulching to reduce evaporation
• Rainwater harvesting for supplementary irrigation
• Drip irrigation with fertigation for efficiency

🚰 **Water Quality**:
• Test water for salinity and pH
• Avoid using water with high salt content
• Filter water to prevent drip system clogging

Check our Water Recommendation feature for crop-specific water requirements!"""
    
    def handle_market_query(self):
        """Provide market and pricing advice"""
        return """Market intelligence helps maximize farm profits:

💰 **Price Discovery**:
• Check local mandi rates regularly
• Use e-NAM platform for national prices
• Monitor market trends and seasonal variations

📊 **Profit Maximization**:
• Reduce input costs through efficient practices
• Time your sales to avoid glut periods
• Explore direct marketing and farmer groups
• Value addition through processing

🤝 **Marketing Channels**:
• Local mandis and APMCs
• Contract farming for price stability
• Direct selling to consumers
• Online agricultural marketplaces

📈 **Risk Management**:
• Diversify crops to spread risk
• Use futures markets for price hedging
• Store produce when prices are low (if feasible)

Use our Market Analysis feature in the app for real-time price trends!"""
    
    def handle_schemes_query(self):
        """Provide information about government schemes"""
        return """Government schemes available for farmers:

💵 **Income Support**:
• **PM-KISAN**: ₹6000/year direct income support
• State-specific farmer welfare schemes

🛡️ **Insurance Schemes**:
• **Pradhan Mantri Fasal Bima Yojana (PMFBY)**: Crop insurance at low premiums
• Coverage for natural calamities and yield losses

� **Credit & Loans**:
• **Kisan Credit Card (KCC)**: Low-interest agricultural loans
• Short-term crop loans at subsidized rates
• Long-term loans for farm equipment

🎯 **Input Subsidies**:
• Fertilizer subsidies
• Seed subsidies
• Farm mechanization schemes
• Drip/sprinkler irrigation subsidies

📚 **Training & Extension**:
• Krishi Vigyan Kendras (KVKs) for training
• Soil Health Card scheme
• E-NAM for better market access

Check our Government Schemes page in the app for detailed information and eligibility!"""
    
    def handle_tomato_query(self):
        """Provide comprehensive tomato cultivation information"""
        return """🍅 **Tomato Cultivation Guide**

**Overview:**
Tomato is a warm-season crop that thrives in well-drained soil with pH 6.0-7.0. It requires 20-25°C temperature and 600-800mm annual rainfall.

**Cultivation Tips:**
• **Soil**: Well-drained loamy soil rich in organic matter
• **Planting**: Transplant 30-day seedlings, spacing 60×45 cm
• **Water**: Drip irrigation recommended, 25-30 liters per plant weekly
• **Fertilizers**: Apply NPK 120:80:50 kg/hectare + FYM 25 tons/hectare

**Common Diseases:**
🦠 **Early Blight**: Brown circular spots on leaves - use copper fungicide
🦠 **Late Blight**: Water-soaked lesions - apply Mancozeb or Metalaxyl
🦠 **Wilt**: Plant wilting despite moisture - use resistant varieties
🦠 **Leaf Curl Virus**: Curled, stunted leaves - control whiteflies

**Pest Management:**
🐛 **Fruit Borer**: Apply neem oil or Bt spray
🐛 **Whitefly**: Use yellow sticky traps + neem spray
🐛 **Aphids**: Release ladybugs or spray soap solution

**Harvesting**: 60-90 days after transplanting when fruits turn red. Use our app's features for soil testing and disease detection for better tomato cultivation! 🌱"""
    
    def handle_wheat_query(self):
        """Provide wheat cultivation information"""
        return """🌾 **Wheat Cultivation Guide**

**Overview:**
Wheat is a rabi (winter) crop requiring 10-25°C temperature and 450-650mm rainfall. Best suited for well-drained loamy soils with pH 6.5-7.5.

**Cultivation Tips:**
• **Sowing Time**: October-November in most regions
• **Seed Rate**: 100-125 kg/hectare for timely sowing
• **Spacing**: Line sowing at 20-22.5 cm row spacing
• **Irrigation**: 4-6 irrigations at critical stages

**Fertilizer Management:**
Apply NPK 120:60:40 kg/hectare in split doses:
• Full P & K + 1/3 N as basal
• 1/3 N at first irrigation (21 days)
• 1/3 N at tillering stage

**Common Diseases & Control:**
🦠 **Rust**: Yellow/brown pustules - spray Propiconazole
🦠 **Powdery Mildew**: White powder on leaves - use Sulfur-based fungicide
🦠 **Loose Smut**: Black spores in ear - treat seeds with Vitavax

**Harvesting**: 120-150 days when grains are hard and moisture content is 20-25%."""
    
    def handle_rice_query(self):
        """Provide rice cultivation information"""
        return """🍚 **Rice Cultivation Guide**

**Overview:**
Rice is a kharif (monsoon) crop requiring 20-35°C temperature and 1500-2000mm rainfall. Grows best in clay or clay loam soil with pH 5.5-7.0.

**Cultivation Tips:**
• **Nursery**: Sow in June, transplant after 25-30 days
• **Spacing**: 20×15 cm for transplanted rice
• **Water**: Maintain 5-10 cm standing water throughout growth
• **Duration**: Short (100-110 days), Medium (110-130 days), Long (>130 days)

**Fertilizer Application:**
NPK 120:60:60 kg/hectare:
• Apply full P & K + 50% N at transplanting
• 25% N at tillering (20-25 days)
• 25% N at panicle initiation (40-45 days)

**Disease Management:**
🦠 **Blast**: Grey/brown lesions - spray Tricyclazole
🦠 **Bacterial Leaf Blight**: Yellow leaves - use Streptocycline
🦠 **Sheath Blight**: Lesions on sheaths - apply Hexaconazole

**Pests**: Stem borer, leaf folder - use pheromone traps and neem products."""
    
    def handle_cotton_query(self):
        """Provide cotton cultivation information"""
        return """🌿 **Cotton Cultivation Guide**

**Overview:**
Cotton requires 21-27°C temperature, 500-1000mm rainfall, and deep well-drained black or alluvial soil with pH 6.5-8.0.

**Cultivation Tips:**
• **Sowing**: April-May for rainfed, May-June for irrigated
• **Spacing**: 90×60 cm for Bt cotton
• **Seed Rate**: 10-12 kg/hectare
• **Irrigation**: 5-6 irrigations at critical stages

**Fertilizer Management:**
Apply NPK 80:40:40 kg/hectare:
• Full dose of P & K at sowing
• Split nitrogen: 50% at sowing, 50% at flowering

**Major Pests & Control:**
🐛 **Bollworm**: Use Bt cotton varieties + pheromone traps
🐛 **Whitefly**: Causes leaf curl virus - spray neem oil
🐛 **Aphids**: Suck sap from tender parts - use imidacloprid

**Diseases:**
🦠 **Wilt**: Use resistant varieties and crop rotation
🦠 **Root Rot**: Improve drainage, treat seeds with Trichoderma

**Harvesting**: 150-180 days, pick bolls when fully opened."""
    
    def handle_maize_query(self):
        """Provide maize cultivation information"""
        return """🌽 **Maize/Corn Cultivation Guide**

**Overview:**
Maize grows in kharif and rabi seasons, requires 21-27°C temperature, 600-1200mm rainfall, and well-drained loamy soil with pH 5.5-7.5.

**Cultivation Tips:**
• **Sowing**: Kharif (June-July), Rabi (Oct-Nov), Spring (Feb-Mar)
• **Spacing**: 60×20 cm for normal varieties, 75×25 cm for hybrids
• **Seed Rate**: 18-20 kg/hectare
• **Irrigation**: 4-5 irrigations required

**Fertilizer Recommendation:**
Apply NPK 120:60:40 kg/hectare:
• 50% N + full P & K at sowing
• 25% N at knee-high stage (25-30 days)
• 25% N at flowering (45-50 days)

**Disease Management:**
🦠 **Blight**: Spray Mancozeb at first sign
🦠 **Rust**: Use resistant varieties, apply fungicides
🦠 **Downy Mildew**: Treat seeds with Metalaxyl

**Pest Control:**
🐛 **Stem Borer**: Apply carbofuran granules in leaf whorl
🐛 **Fall Armyworm**: Use pheromone traps + bio-pesticides

**Harvesting**: 80-110 days when kernels are hard and moisture is 20-25%."""

# Initialize chatbot
chatbot = AgriculturalChatbot(use_ai=USE_AI_CHATBOT)

@app.route('/')
def home():
    """Health check endpoint"""
    return jsonify({
        'status': 'success',
        'message': 'FarmOps Backend API is running',
        'version': '1.0.0'
    }), 200

@app.route('/api/check-user', methods=['POST'])
def check_user():
    """
    Check if user exists in database
    Expected JSON body: { "mobile_phone": "1234567890" }
    """
    try:
        data = request.get_json()
        
        # Validate mobile phone field
        if not data or 'mobile_phone' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Mobile phone number is required'
            }), 400
        
        mobile_phone = data['mobile_phone']
        
        # Basic validation
        if not mobile_phone or len(str(mobile_phone).strip()) != 10:
            return jsonify({
                'status': 'error',
                'message': 'Please enter a valid 10-digit mobile phone number'
            }), 400
        
        # Check if user exists
        existing_user = users_collection.find_one({'mobile_phone': mobile_phone})
        
        if existing_user:
            return jsonify({
                'status': 'success',
                'exists': True,
                'message': 'User account found'
            }), 200
        else:
            return jsonify({
                'status': 'success',
                'exists': False,
                'message': 'No account found with this mobile number'
            }), 200
            
    except Exception as e:
        print(f"Error in check_user endpoint: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}'
        }), 500

@app.route('/api/create-user', methods=['POST'])
def create_user():
    """
    Create a new user account
    Expected JSON body: { "mobile_phone": "1234567890" }
    """
    try:
        data = request.get_json()
        
        # Validate mobile phone field
        if not data or 'mobile_phone' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Mobile phone number is required'
            }), 400
        
        mobile_phone = data['mobile_phone']
        
        # Basic validation
        if not mobile_phone or len(str(mobile_phone).strip()) != 10:
            return jsonify({
                'status': 'error',
                'message': 'Please enter a valid 10-digit mobile phone number'
            }), 400
        
        # Check if user already exists
        existing_user = users_collection.find_one({'mobile_phone': mobile_phone})
        
        if existing_user:
            return jsonify({
                'status': 'error',
                'message': 'User already exists with this mobile number'
            }), 400
        
        # Create new user
        new_user = {
            'mobile_phone': mobile_phone,
            'created_at': datetime.utcnow(),
            'profile': {
                'name': '',
                'location': '',
                'land_size': '',
                'preferred_language': 'en'
            }
        }
        
        result = users_collection.insert_one(new_user)
        
        # Get the created user (without MongoDB's _id)
        created_user = users_collection.find_one({'_id': result.inserted_id})
        created_user['_id'] = str(created_user['_id'])  # Convert ObjectId to string
        
        print(f"✅ New user created: {mobile_phone}")
        
        return jsonify({
            'status': 'success',
            'message': 'User account created successfully',
            'user': created_user
        }), 201
            
    except Exception as e:
        print(f"Error in create_user endpoint: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}'
        }), 500

@app.route('/api/login', methods=['POST'])
def login():
    """
    Direct login endpoint - creates or logs in user with mobile number
    Expected JSON body: { "mobile_phone": "1234567890" }
    """
    try:
        data = request.get_json()
        
        # Validate mobile phone field
        if not data or 'mobile_phone' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Mobile phone number is required'
            }), 400
        
        mobile_phone = data['mobile_phone']
        
        # Basic validation for mobile phone
        if not mobile_phone or len(str(mobile_phone).strip()) != 10:
            return jsonify({
                'status': 'error',
                'message': 'Please enter a valid 10-digit mobile phone number'
            }), 400
        
        # Check if user exists
        existing_user = users_collection.find_one({'mobile_phone': mobile_phone})
        
        if existing_user:
            # Update last login time
            users_collection.update_one(
                {'mobile_phone': mobile_phone},
                {'$set': {'last_login': datetime.utcnow()}}
            )
            
            return jsonify({
                'status': 'success',
                'message': 'Login successful',
                'user': {
                    'mobile_phone': mobile_phone,
                    'user_id': str(existing_user['_id']),
                    'created_at': existing_user.get('created_at').isoformat() if existing_user.get('created_at') else None,
                    'last_login': datetime.utcnow().isoformat()
                }
            }), 200
        else:
            # Create new user
            new_user = {
                'mobile_phone': mobile_phone,
                'created_at': datetime.utcnow(),
                'last_login': datetime.utcnow()
            }
            
            result = users_collection.insert_one(new_user)
            
            return jsonify({
                'status': 'success',
                'message': 'User created and logged in successfully',
                'user': {
                    'mobile_phone': mobile_phone,
                    'user_id': str(result.inserted_id),
                    'created_at': new_user['created_at'].isoformat(),
                    'last_login': new_user['last_login'].isoformat()
                }
            }), 201
            
    except Exception as e:
        print(f"Error in login endpoint: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}'
        }), 500

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users (for testing purposes)"""
    try:
        users = list(users_collection.find({}, {'_id': 0}))
        return jsonify({
            'status': 'success',
            'count': len(users),
            'users': users
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}'
        }), 500

@app.route('/api/market/data', methods=['GET'])
def get_market_dropdown_data():
    """
    Get state hierarchy for market analysis dropdown
    Returns the structure needed to populate state dropdown
    """
    try:
        # This would ideally come from a cached file or database
        # For now, we'll make an API call to get available states
        url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        params = {
            "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
            "format": "json",
            "limit": 1000
        }
        
        response = requests.get(url, params=params, timeout=10)
        
        if response.status_code == 200:
            records = response.json().get("records", [])
            states = sorted(set(r.get("state", "") for r in records if r.get("state")))
            
            # Return as a dictionary with states as keys (to match Flask app format)
            dropdown_data = {state: {} for state in states}
            
            return jsonify(dropdown_data), 200
        else:
            return jsonify({'status': 'error', 'message': 'Failed to fetch market data'}), 500
            
    except Exception as e:
        print(f"Error in get_market_dropdown_data: {e}")
        return jsonify({'status': 'error', 'message': f'Server error: {str(e)}'}), 500

@app.route('/api/market/mandis/<state>', methods=['GET'])
def get_mandis(state):
    """
    Get list of mandis (markets) for a specific state
    """
    try:
        url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        params = {
            "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
            "format": "json",
            "filters[state]": state,
            "limit": 500
        }
        
        response = requests.get(url, params=params, timeout=10)
        
        if response.status_code == 200:
            records = response.json().get("records", [])
            mandis = sorted(set(r.get("market", "") for r in records if r.get("market")))
            return jsonify(mandis), 200
        else:
            return jsonify([]), 200
            
    except Exception as e:
        print(f"Error in get_mandis: {e}")
        return jsonify([]), 200

@app.route('/api/market/crops/<state>/<mandi>', methods=['GET'])
def get_crops_for_mandi(state, mandi):
    """
    Get list of crops available in a specific mandi of a state
    """
    try:
        url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        params = {
            "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
            "format": "json",
            "filters[state]": state,
            "filters[market]": mandi,
            "limit": 500
        }
        
        response = requests.get(url, params=params, timeout=15)
        
        if response.status_code == 200:
            records = response.json().get("records", [])
            crops = sorted(set(r.get("commodity", "").strip() for r in records if r.get("commodity")))
            return jsonify(crops), 200
        else:
            return jsonify([]), 200
            
    except Exception as e:
        print(f"Error in get_crops_for_mandi: {e}")
        return jsonify([]), 200

@app.route('/api/market/prices', methods=['GET'])
def get_market_prices():
    """
    Get market prices for a specific crop in a specific mandi
    Returns last 7 days of price data with analysis
    """
    try:
        state = request.args.get('state')
        mandi = request.args.get('mandi')
        crop = request.args.get('crop')
        
        if not state or not mandi or not crop:
            return jsonify({"error": "Missing required parameters: state, mandi, and crop"}), 400
        
        url = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        params = {
            "api-key": "579b464db66ec23bdd0000018566a861bdb54c7f4945a93840b31b5d",
            "format": "json",
            "filters[state]": state,
            "filters[market]": mandi,
            "filters[commodity]": crop,
            "limit": 500
        }
        
        response = requests.get(url, params=params, timeout=15)
        
        if response.status_code != 200:
            return jsonify({"error": "Failed to fetch data from government API"}), 500
        
        data = response.json().get("records", [])
        history = []
        today = datetime.today()
        seven_days_ago = today - timedelta(days=7)
        
        # Parse and filter data for last 7 days
        for row in data:
            try:
                date_obj = datetime.strptime(row["arrival_date"], "%d/%m/%Y")
                if date_obj >= seven_days_ago:
                    price = float(row["modal_price"])
                    history.append({
                        "date": row["arrival_date"],
                        "modal_price": price
                    })
            except (ValueError, KeyError) as e:
                continue
        
        # Sort by date
        history.sort(key=lambda x: datetime.strptime(x["date"], "%d/%m/%Y"))
        
        if not history:
            return jsonify({"error": "No data found for given filters in last 7 days"}), 404
        
        # Calculate statistics
        latest = history[-1]
        prices = [h["modal_price"] for h in history]
        avg_7d = sum(prices) / len(prices)
        
        # Calculate percentage change from first to last
        if len(history) > 1:
            change = ((latest["modal_price"] - history[0]["modal_price"]) / history[0]["modal_price"]) * 100
        else:
            change = 0.0
        
        return jsonify({
            "crop": crop,
            "mandi": mandi,
            "state": state,
            "history": history,
            "latest": {
                "modal_price": latest["modal_price"],
                "change_pct": round(change, 2),
                "avg_7d": round(avg_7d, 2)
            }
        }), 200
        
    except Exception as e:
        print(f"Error in get_market_prices: {e}")
        return jsonify({"error": f"Server error: {str(e)}"}), 500

@app.route('/api/get-location', methods=['GET'])
def get_location():
    """
    Get user's location based on IP address using ipapi.co free service
    Returns latitude, longitude, city, and country
    """
    try:
        # Get client IP address
        # Check for forwarded IP first (if behind proxy)
        client_ip = request.headers.get('X-Forwarded-For', request.remote_addr)
        if client_ip:
            # Take the first IP if multiple are present
            client_ip = client_ip.split(',')[0].strip()
        
        # For local development, use a default IP (or ipapi will detect our public IP)
        # If running locally, ipapi.co will use your public IP automatically
        
        # If localhost/127.0.0.1, use the API without IP to get actual public IP location
        if client_ip in ['127.0.0.1', 'localhost', '::1']:
            location_url = 'https://ipapi.co/json/'
        else:
            location_url = f'https://ipapi.co/{client_ip}/json/'
        
        response = requests.get(location_url, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            
            # Check if we got valid location data
            if 'latitude' in data and 'longitude' in data:
                return jsonify({
                    'status': 'success',
                    'location': {
                        'latitude': data.get('latitude'),
                        'longitude': data.get('longitude'),
                        'city': data.get('city', 'Unknown'),
                        'region': data.get('region', ''),
                        'country': data.get('country_name', 'Unknown'),
                        'country_code': data.get('country_code', ''),
                        'timezone': data.get('timezone', ''),
                    },
                    'ip': data.get('ip', client_ip)
                }), 200
            else:
                # Return default location (New Delhi) if geolocation fails
                return jsonify({
                    'status': 'success',
                    'location': {
                        'latitude': 28.6139,
                        'longitude': 77.2090,
                        'city': 'New Delhi',
                        'region': 'Delhi',
                        'country': 'India',
                        'country_code': 'IN',
                        'timezone': 'Asia/Kolkata',
                    },
                    'ip': client_ip,
                    'note': 'Using default location (New Delhi)'
                }), 200
        else:
            # Fallback to default location
            return jsonify({
                'status': 'success',
                'location': {
                    'latitude': 28.6139,
                    'longitude': 77.2090,
                    'city': 'New Delhi',
                    'region': 'Delhi',
                    'country': 'India',
                    'country_code': 'IN',
                    'timezone': 'Asia/Kolkata',
                },
                'ip': client_ip,
                'note': 'Using default location (New Delhi) - API unavailable'
            }), 200
            
    except Exception as e:
        print(f"Error getting location: {e}")
        # Return default location on error
        return jsonify({
            'status': 'success',
            'location': {
                'latitude': 28.6139,
                'longitude': 77.2090,
                'city': 'New Delhi',
                'region': 'Delhi',
                'country': 'India',
                'country_code': 'IN',
                'timezone': 'Asia/Kolkata',
            },
            'note': 'Using default location (New Delhi) - Error occurred'
        }), 200

# ==================== CROP RECOMMENDATION ENDPOINTS ====================

@app.route('/api/crop/states', methods=['GET'])
def get_states():
    """Get list of all states"""
    try:
        states = crop_service.get_states()
        return jsonify({
            'status': 'success',
            'states': states,
            'count': len(states)
        }), 200
    except Exception as e:
        print(f"Error getting states: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch states: {str(e)}'
        }), 500

@app.route('/api/crop/districts/<state>', methods=['GET'])
def get_districts(state):
    """Get list of districts for a state"""
    try:
        districts = crop_service.get_districts(state)
        return jsonify({
            'status': 'success',
            'state': state,
            'districts': districts,
            'count': len(districts)
        }), 200
    except Exception as e:
        print(f"Error getting districts: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch districts: {str(e)}'
        }), 500

@app.route('/api/crop/blocks/<state>/<district>', methods=['GET'])
def get_blocks(state, district):
    """Get list of blocks for a district"""
    try:
        blocks = crop_service.get_blocks(state, district)
        return jsonify({
            'status': 'success',
            'state': state,
            'district': district,
            'blocks': blocks,
            'count': len(blocks)
        }), 200
    except Exception as e:
        print(f"Error getting blocks: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch blocks: {str(e)}'
        }), 500

@app.route('/api/crop/villages/<state>/<district>/<block>', methods=['GET'])
def get_villages(state, district, block):
    """Get list of villages for a block"""
    try:
        villages = crop_service.get_villages(state, district, block)
        return jsonify({
            'status': 'success',
            'state': state,
            'district': district,
            'block': block,
            'villages': villages,
            'count': len(villages)
        }), 200
    except Exception as e:
        print(f"Error getting villages: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch villages: {str(e)}'
        }), 500

@app.route('/api/crop/dropdown-data', methods=['GET'])
def get_dropdown_data():
    """Get complete dropdown hierarchy"""
    try:
        data = crop_service.get_dropdown_data()
        return jsonify({
            'status': 'success',
            'data': data,
            'states_count': len(data)
        }), 200
    except Exception as e:
        print(f"Error getting dropdown data: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch dropdown data: {str(e)}'
        }), 500

@app.route('/api/crop/suitability', methods=['POST'])
def get_crop_suitability():
    """
    Get crop suitability for a specific location
    Expected JSON body: {
        "state": "Maharashtra",
        "district": "Pune",
        "block": "Haveli",
        "village": "Katraj"
    }
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['state', 'district', 'block', 'village']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'status': 'error',
                    'message': f'Missing required field: {field}'
                }), 400
        
        result = crop_service.get_crop_suitability(
            state=data['state'],
            district=data['district'],
            block=data['block'],
            village=data['village']
        )
        
        if result:
            return jsonify({
                'status': 'success',
                'location': {
                    'state': data['state'],
                    'district': data['district'],
                    'block': data['block'],
                    'village': data['village']
                },
                'crops': result
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'No crop data found for this location'
            }), 404
            
    except Exception as e:
        print(f"Error getting crop suitability: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch crop suitability: {str(e)}'
        }), 500

@app.route('/api/crop/evaluate', methods=['POST'])
def evaluate_crops():
    """
    Evaluate crops based on soil and climate data
    Expected JSON body: {
        "Nitrogen": "High (81–100%)",
        "Phosphorus": "Medium (41–80%)",
        ... (16 parameters total)
    }
    """
    try:
        data = request.get_json()
        
        # Required parameters
        required_params = [
            'Nitrogen', 'Phosphorus', 'Potassium', 'OC', 'EC', 'pH',
            'Copper', 'Boron', 'Sulphur', 'Iron', 'Zinc', 'Manganese',
            'Temperature_Summer', 'Temperature_Winter', 'Temperature_Monsoon', 'Rainfall'
        ]
        
        # Validate all parameters are present
        missing_params = [p for p in required_params if p not in data]
        if missing_params:
            return jsonify({
                'status': 'error',
                'message': f'Missing required parameters: {", ".join(missing_params)}'
            }), 400
        
        # Evaluate crops
        results = crop_service.evaluate_all_crops(data)
        
        # Group by suitability
        grouped = {
            'Highly Suitable': [],
            'Moderately Suitable': [],
            'Not Suitable': []
        }
        
        for crop, suitability in results.items():
            grouped[suitability].append(crop)
        
        return jsonify({
            'status': 'success',
            'crops': results,
            'grouped': grouped,
            'summary': {
                'highly_suitable': len(grouped['Highly Suitable']),
                'moderately_suitable': len(grouped['Moderately Suitable']),
                'not_suitable': len(grouped['Not Suitable']),
                'total': len(results)
            }
        }), 200
        
    except Exception as e:
        print(f"Error evaluating crops: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to evaluate crops: {str(e)}'
        }), 500

@app.route('/api/crop/attributes', methods=['GET'])
def get_crop_attributes():
    """Get list of all attribute options for the soil recommendation form"""
    try:
        attributes = {
            "Nitrogen": ["High (81–100%)", "Medium (51–80%)", "Low (0–50%)"],
            "Phosphorus": ["High (81–100%)", "Medium (41–80%)", "Low (0–40%)"],
            "Potassium": ["High (81–100%)", "Medium (31–80%)", "Low (0–30%)"],
            "OC": ["High (> 0.75%)", "Medium (0.5–0.75%)", "Low (< 0.5%)"],
            "EC": ["Non-Saline (< 4 dS/m)", "Saline (≥ 4 dS/m)"],
            "pH": ["Alkaline (above 7.5)", "Neutral (6.5–7.5)", "Acidic (below 6.5)"],
            "Copper": ["Sufficient (81–100%)", "Deficient (0–50%)"],
            "Boron": ["Sufficient (81–100%)", "Deficient (0–50%)"],
            "Sulphur": ["Sufficient (81–100%)", "Deficient (0–50%)"],
            "Iron": ["Sufficient (81–100%)", "Deficient (0–50%)"],
            "Zinc": ["Sufficient (86–100%)", "Deficient (0–60%)"],
            "Manganese": ["Sufficient (81–100%)", "Deficient (0–50%)"],
            "Temperature_Summer": [
                "Low (< 28°C – Too cool for summer crops)",
                "Medium (28–35°C – Ideal for warm-season crops)",
                "High (> 35°C – Heat stress risk)"
            ],
            "Temperature_Winter": [
                "Low (< 10°C – Too cold for most crops)",
                "Medium (10–20°C – Ideal for rabi crops)",
                "High (> 20°C – May hinder wheat filling)"
            ],
            "Temperature_Monsoon": [
                "Low (< 22°C – Poor germination)",
                "Medium (22–30°C – Ideal for kharif crops)",
                "High (> 30°C – Fungal stress risk)"
            ],
            "Rainfall": [
                "High (1000–1500 mm – Ideal rainfed range)",
                "Medium (500–1000 mm – May need irrigation)",
                "Low (< 500 mm – Highly insufficient)"
            ]
        }
        
        return jsonify({
            'status': 'success',
            'attributes': attributes,
            'total_attributes': len(attributes)
        }), 200
        
    except Exception as e:
        print(f"Error getting attributes: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to fetch attributes: {str(e)}'
        }), 500

@app.route('/api/crop/growth-timeline', methods=['POST'])
def generate_growth_timeline():
    """
    Generate dynamic crop growth timeline based on crop and soil conditions
    Accepts: crop_name, soil_type (optional), soil_data (optional), location_data (optional)
    """
    try:
        data = request.get_json()
        crop_name = data.get('crop_name', '').strip()
        
        if not crop_name:
            return jsonify({
                'status': 'error',
                'message': 'Crop name is required'
            }), 400
        
        # Determine soil type from various sources
        soil_type = data.get('soil_type', 'loamy_moist')
        
        # If we have location data, we could extract soil type from that
        # (This would require additional data in your Excel file)
        location_data = data.get('location_data')
        soil_data = data.get('soil_data')
        
        # For now, use the provided soil_type or default
        # You can enhance this later to infer soil type from soil_data parameters
        
        result = CropGrowthService.generate_timeline(
            crop_name=crop_name,
            soil_type=soil_type
        )
        
        if result.get('success'):
            return jsonify(result), 200
        else:
            return jsonify(result), 404
            
    except Exception as e:
        print(f"Error generating timeline: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to generate timeline: {str(e)}'
        }), 500


@app.route('/api/crop/water-consumption', methods=['POST'])
def get_water_consumption():
    """
    Get water consumption data for a crop based on soil conditions
    Accepts: crop_name, soil_data (optional), location_data (optional)
    """
    try:
        data = request.get_json()
        crop_name = data.get('crop_name', '').strip()
        
        if not crop_name:
            return jsonify({
                'status': 'error',
                'message': 'Crop name is required'
            }), 400
        
        # Determine soil type from various sources
        soil_type = 'loamy_moist'  # Default
        
        # If we have soil_data, try to infer soil type from parameters
        soil_data = data.get('soil_data')
        if soil_data:
            # You can enhance this logic to infer soil type from soil parameters
            # For example, based on EC, drainage characteristics, etc.
            pass
        
        # If we have location data, use it (would require enhancement)
        location_data = data.get('location_data')
        
        result = CropGrowthService.get_water_consumption(
            crop_name=crop_name,
            soil_type=soil_type
        )
        
        if result.get('success'):
            return jsonify(result), 200
        else:
            return jsonify(result), 404
            
    except Exception as e:
        print(f"Error getting water consumption: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Failed to get water consumption data: {str(e)}'
        }), 500

# ==================== CHATBOT ENDPOINT ====================

@app.route('/chat', methods=['POST'])
def chat():
    """
    Agricultural chatbot endpoint
    Expected JSON body: { "message": "user question here", "user_id": "optional_user_id" }
    """
    try:
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({
                'status': 'error',
                'response': 'Please provide a message.'
            }), 400
        
        user_message = data['message'].strip()
        user_id = data.get('user_id', 'default')
        
        if not user_message:
            return jsonify({
                'status': 'error',
                'response': 'Message cannot be empty.'
            }), 400
        
        print(f"💬 Chat request from user {user_id}: {user_message}")
        
        # Process message through chatbot with conversation history
        bot_response = chatbot.process_message(user_message, user_id)
        
        print(f"🤖 Bot response: {bot_response[:100]}...")
        
        return jsonify({
            'status': 'success',
            'response': bot_response,
            'timestamp': datetime.utcnow().isoformat()
        }), 200
        
    except Exception as e:
        print(f"❌ Error in chat endpoint: {e}")
        return jsonify({
            'status': 'error',
            'response': 'Sorry, I encountered an error. Please try again.'
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for chatbot service"""
    return jsonify({
        'status': 'healthy',
        'service': 'FarmOps Chatbot',
        'version': '1.0.0'
    }), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'True') == 'True'
    app.run(host='0.0.0.0', port=port, debug=debug)
