import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class GovernmentSchemesPage extends StatefulWidget {
  const GovernmentSchemesPage({super.key});

  @override
  State<GovernmentSchemesPage> createState() => _GovernmentSchemesPageState();
}

class _GovernmentSchemesPageState extends State<GovernmentSchemesPage> {
  // User input parameters
  String? selectedState;
  String? landSize;
  String? annualIncome;
  String? farmerCategory;
  String? cropType;

  // Show results flag
  bool showResults = false;
  List<SchemeData> recommendedSchemes = [];

  // Input options
  final List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'All India',
  ];

  final List<String> landSizes = [
    'Marginal (< 1 hectare)',
    'Small (1-2 hectares)',
    'Semi-Medium (2-4 hectares)',
    'Medium (4-10 hectares)',
    'Large (> 10 hectares)',
    'Landless',
  ];

  final List<String> incomeCategories = [
    'Below ₹1 Lakh/year',
    '₹1-3 Lakh/year',
    '₹3-5 Lakh/year',
    'Above ₹5 Lakh/year',
  ];

  final List<String> farmerCategories = [
    'General',
    'SC/ST',
    'OBC',
    'Women Farmer',
    'Youth Farmer (18-40 years)',
  ];

  final List<String> cropTypes = [
    'Cereals (Rice, Wheat, Maize)',
    'Pulses (Dal, Lentils)',
    'Oilseeds (Soybean, Mustard)',
    'Cash Crops (Cotton, Sugarcane)',
    'Horticulture (Fruits, Vegetables)',
    'Dairy/Animal Husbandry',
    'Mixed Farming',
  ];

  // 15+ Government Schemes for Farmers
  final List<SchemeData> allSchemes = [
    SchemeData(
      name: 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
      description:
          'Direct income support of ₹6,000 per year to all landholding farmers in three equal installments.',
      eligibility: [
        'All landholding farmers',
        'Small and marginal farmers priority',
      ],
      benefits: [
        '₹6,000 annual direct cash transfer',
        'Three installments of ₹2,000 each',
        'Direct bank transfer',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      description:
          'Crop insurance scheme providing financial support to farmers in case of crop failure due to natural calamities, pests & diseases.',
      eligibility: [
        'All farmers growing notified crops',
        'Sharecroppers and tenant farmers eligible',
      ],
      benefits: [
        '2% premium for Kharif crops',
        '1.5% premium for Rabi crops',
        '5% for commercial/horticultural crops',
        'Coverage for yield losses',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
      ],
    ),
    SchemeData(
      name: 'PM-KUSUM (Solar Agriculture Scheme)',
      description:
          'Provides financial support to farmers for installing solar pumps and grid-connected solar power plants on barren land.',
      eligibility: [
        'Individual farmers',
        'Group of farmers/FPOs',
        'Farmers with barren/fallow land',
      ],
      benefits: [
        '30% subsidy by Central Government',
        '30% subsidy by State Government',
        'Reduced electricity costs',
        'Additional income from solar power',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: ['₹1-3 Lakh/year', '₹3-5 Lakh/year', 'Above ₹5 Lakh/year'],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Soil Health Card Scheme',
      description:
          'Provides soil health cards to farmers with nutrient status and recommendations for appropriate dosage of nutrients.',
      eligibility: ['All farmers holding agricultural land'],
      benefits: [
        'Free soil testing',
        'Soil nutrient report card',
        'Fertilizer recommendations',
        'Improved crop yield',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'National Agriculture Market (e-NAM)',
      description:
          'Online trading platform for agricultural commodities enabling farmers to get better prices through transparent auction process.',
      eligibility: ['All farmers with produce to sell', 'Traders and buyers'],
      benefits: [
        'Better price discovery',
        'Reduced intermediaries',
        'Pan-India market access',
        'Transparent online bidding',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
      ],
    ),
    SchemeData(
      name: 'Kisan Credit Card (KCC)',
      description:
          'Provides credit support to farmers for crop cultivation, post-harvest expenses, and asset maintenance at subsidized interest rates.',
      eligibility: [
        'All farmers - owner cultivators',
        'Tenant farmers, sharecroppers',
        'SHGs/JLGs of farmers',
      ],
      benefits: [
        'Credit up to ₹3 lakh at 7% interest',
        '2% interest subvention',
        'Additional 3% on prompt repayment',
        'Flexible repayment',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
        'Landless',
      ],
      incomeRange: ['Below ₹1 Lakh/year', '₹1-3 Lakh/year', '₹3-5 Lakh/year'],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Dairy/Animal Husbandry',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Paramparagat Krishi Vikas Yojana (PKVY)',
      description:
          'Promotes organic farming by creating clusters and providing financial assistance for organic inputs, certification, and marketing.',
      eligibility: [
        'Individual farmers interested in organic farming',
        'Groups of 50 farmers forming clusters',
      ],
      benefits: [
        '₹50,000 per hectare over 3 years',
        'Free organic certification',
        'Training on organic farming',
        'Better market linkage',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
      ],
      incomeRange: ['Below ₹1 Lakh/year', '₹1-3 Lakh/year', '₹3-5 Lakh/year'],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'National Mission for Sustainable Agriculture (NMSA)',
      description:
          'Promotes sustainable agriculture practices including water conservation, soil health management, and resource efficiency.',
      eligibility: ['All farmers', 'Focus on rainfed areas'],
      benefits: [
        'Subsidy on farm equipment',
        'Drip/sprinkler irrigation subsidy',
        'Training on sustainable practices',
        'Watershed development support',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Pradhan Mantri Krishi Sinchayee Yojana (PMKSY)',
      description:
          'Aims to expand cultivated area with assured irrigation and improve water use efficiency through micro-irrigation systems.',
      eligibility: ['All categories of farmers', 'FPOs, Self Help Groups'],
      benefits: [
        'Drip/sprinkler subsidy up to 55%',
        'Borewell/tube well subsidy',
        'Farm pond construction',
        'Water conservation structures',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Mission for Integrated Development of Horticulture (MIDH)',
      description:
          'Provides financial support for area expansion, productivity enhancement, and post-harvest management of horticultural crops.',
      eligibility: ['Individual farmers', 'Groups of farmers', 'FPOs'],
      benefits: [
        '40-50% subsidy on planting material',
        'Protected cultivation subsidy',
        'Pack house/cold storage support',
        'Market linkage assistance',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: ['Horticulture (Fruits, Vegetables)'],
    ),
    SchemeData(
      name: 'National Livestock Mission',
      description:
          'Aims at sustainable development of livestock sector focusing on breed improvement, feed & fodder, and health infrastructure.',
      eligibility: ['Dairy farmers', 'Livestock rearers', 'Entrepreneurs'],
      benefits: [
        '25-50% subsidy on dairy units',
        'Breed improvement support',
        'Fodder development',
        'Insurance coverage',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
        'Landless',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: ['Dairy/Animal Husbandry'],
    ),
    SchemeData(
      name: 'Sub-Mission on Agricultural Mechanization (SMAM)',
      description:
          'Promotes farm mechanization to increase productivity and reduce drudgery of farmers through subsidies on agricultural machinery.',
      eligibility: [
        'Individual farmers',
        'Cooperative societies',
        'FPOs',
        'Custom Hiring Centers',
      ],
      benefits: [
        '40-50% subsidy on farm equipment',
        'Additional subsidy for SC/ST/Women',
        'Training on machine operation',
        'Custom Hiring Center support',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Rashtriya Krishi Vikas Yojana (RKVY)',
      description:
          'State-specific agricultural development scheme providing flexibility to states to plan and execute projects based on local needs.',
      eligibility: [
        'All categories of farmers',
        'State governments implement projects',
      ],
      benefits: [
        'Infrastructure development',
        'Value addition projects',
        'Marketing support',
        'Technology adoption',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Dairy/Animal Husbandry',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'National Food Security Mission (NFSM)',
      description:
          'Focuses on increasing production and productivity of rice, wheat, pulses, and coarse cereals through area expansion and productivity enhancement.',
      eligibility: [
        'All farmers growing targeted crops',
        'Focus on rainfed areas',
      ],
      benefits: [
        'Free/subsidized seeds',
        'Training on improved practices',
        'Micronutrient supply',
        'Farm equipment subsidy',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: ['Below ₹1 Lakh/year', '₹1-3 Lakh/year', '₹3-5 Lakh/year'],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: ['Cereals (Rice, Wheat, Maize)', 'Pulses (Dal, Lentils)'],
    ),
    SchemeData(
      name: 'National Beekeeping & Honey Mission (NBHM)',
      description:
          'Promotes scientific beekeeping and honey production to increase farmers\' income and enhance crop pollination.',
      eligibility: ['Individual farmers', 'Women SHGs', 'Youth entrepreneurs'],
      benefits: [
        '90% subsidy on beekeeping equipment for NE states',
        '40-75% subsidy for other states',
        'Training programs',
        'Market linkage',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Landless',
      ],
      incomeRange: ['Below ₹1 Lakh/year', '₹1-3 Lakh/year', '₹3-5 Lakh/year'],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: ['Horticulture (Fruits, Vegetables)', 'Mixed Farming'],
    ),
    SchemeData(
      name: 'Modified Interest Subvention Scheme (MISS)',
      description:
          'Provides short-term crop loans up to ₹3 lakh at concessional interest rates with additional incentives for prompt repayment.',
      eligibility: [
        'All farmers availing crop loans',
        'Tenant farmers with land records',
      ],
      benefits: [
        'Interest rate reduced to 7%',
        'Additional 3% on prompt repayment',
        'Effective rate of 4% per annum',
        'Post-harvest loan for 6 months',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: ['Below ₹1 Lakh/year', '₹1-3 Lakh/year', '₹3-5 Lakh/year'],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
    SchemeData(
      name: 'Pradhan Mantri Matsya Sampada Yojana (PMMSY)',
      description:
          'Focuses on sustainable development of fisheries sector with infrastructure development and increased fish production.',
      eligibility: [
        'Fish farmers',
        'Fisheries cooperatives',
        'Entrepreneurs in fisheries',
      ],
      benefits: [
        '40-60% subsidy on pond construction',
        'Fish seed subsidy',
        'Cold chain infrastructure',
        'Market development support',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Marginal (< 1 hectare)',
        'Small (1-2 hectares)',
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
        'Landless',
      ],
      incomeRange: [
        'Below ₹1 Lakh/year',
        '₹1-3 Lakh/year',
        '₹3-5 Lakh/year',
        'Above ₹5 Lakh/year',
      ],
      categories: [
        'General',
        'SC/ST',
        'OBC',
        'Women Farmer',
        'Youth Farmer (18-40 years)',
      ],
      relevantCrops: ['Mixed Farming'],
    ),
    SchemeData(
      name: 'Kisan Drone Scheme',
      description:
          'Provides financial assistance to farmers for purchasing drones for agricultural purposes including spraying, seeding, and land records.',
      eligibility: [
        'Individual farmers',
        'FPOs',
        'Agriculture graduates',
        'Custom Hiring Centers',
      ],
      benefits: [
        '40-50% subsidy on drones',
        '75% subsidy for FPOs in NE/hilly areas',
        'Training on drone operation',
        'Reduced input costs',
      ],
      applicableStates: ['All India'],
      landRequirement: [
        'Semi-Medium (2-4 hectares)',
        'Medium (4-10 hectares)',
        'Large (> 10 hectares)',
      ],
      incomeRange: ['₹1-3 Lakh/year', '₹3-5 Lakh/year', 'Above ₹5 Lakh/year'],
      categories: ['General', 'SC/ST', 'OBC', 'Youth Farmer (18-40 years)'],
      relevantCrops: [
        'Cereals (Rice, Wheat, Maize)',
        'Pulses (Dal, Lentils)',
        'Oilseeds (Soybean, Mustard)',
        'Cash Crops (Cotton, Sugarcane)',
        'Horticulture (Fruits, Vegetables)',
        'Mixed Farming',
      ],
    ),
  ];

  void _filterSchemes() {
    if (selectedState == null ||
        landSize == null ||
        annualIncome == null ||
        farmerCategory == null ||
        cropType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Filter schemes based on user inputs
    List<SchemeData> filtered = allSchemes.where((scheme) {
      bool stateMatch =
          scheme.applicableStates.contains('All India') ||
          scheme.applicableStates.contains(selectedState);
      bool landMatch = scheme.landRequirement.contains(landSize);
      bool incomeMatch = scheme.incomeRange.contains(annualIncome);
      bool categoryMatch = scheme.categories.contains(farmerCategory);
      bool cropMatch = scheme.relevantCrops.contains(cropType);

      return stateMatch &&
          landMatch &&
          incomeMatch &&
          categoryMatch &&
          cropMatch;
    }).toList();

    setState(() {
      recommendedSchemes = filtered;
      showResults = true;
    });

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No schemes found matching your criteria. Try adjusting filters.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF008575),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      selectedState = null;
      landSize = null;
      annualIncome = null;
      farmerCategory = null;
      cropType = null;
      showResults = false;
      recommendedSchemes = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and logo
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: context.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Farm-Ops',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: context.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Input parameters card (shown when not displaying results)
                    if (!showResults) ...[
                      _buildInputCard(),
                      const SizedBox(height: 24),

                      // Find Schemes Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _filterSchemes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008575),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'Find Suitable Schemes',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Results section
                    if (showResults) ...[
                      _buildResultsHeader(),
                      const SizedBox(height: 16),
                      ...recommendedSchemes.map(
                        (scheme) => _buildSchemeCard(scheme),
                      ),
                      if (recommendedSchemes.isEmpty) _buildEmptyState(),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom navigation bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Icon
          Image.asset(
            'assets/images/government_schemes.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.account_balance,
                size: 80,
                color: context.primaryColor,
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Government Schemes',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover agricultural schemes\ntailored to your farming profile',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Your Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'State',
            selectedState,
            states,
            (value) => setState(() => selectedState = value),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Land Size',
            landSize,
            landSizes,
            (value) => setState(() => landSize = value),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Annual Income',
            annualIncome,
            incomeCategories,
            (value) => setState(() => annualIncome = value),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Farmer Category',
            farmerCategory,
            farmerCategories,
            (value) => setState(() => farmerCategory = value),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Primary Crop Type',
            cropType,
            cropTypes,
            (value) => setState(() => cropType = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: context.secondaryTextColor,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: context.primaryColor),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.textColor,
              ),
              dropdownColor: context.cardColor,
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Schemes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${recommendedSchemes.length} schemes found',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetFilters,
            tooltip: 'Reset Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(SchemeData scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scheme name with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.lightGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified,
                  color: context.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scheme.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            scheme.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Eligibility
          _buildInfoSection(
            'Eligibility',
            scheme.eligibility,
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),

          // Benefits
          _buildInfoSection(
            'Key Benefits',
            scheme.benefits,
            Icons.star_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: context.primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.secondaryTextColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: context.secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No schemes match your criteria',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters to see more schemes',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }
}

// Scheme data model
class SchemeData {
  final String name;
  final String description;
  final List<String> eligibility;
  final List<String> benefits;
  final List<String> applicableStates;
  final List<String> landRequirement;
  final List<String> incomeRange;
  final List<String> categories;
  final List<String> relevantCrops;

  SchemeData({
    required this.name,
    required this.description,
    required this.eligibility,
    required this.benefits,
    required this.applicableStates,
    required this.landRequirement,
    required this.incomeRange,
    required this.categories,
    required this.relevantCrops,
  });
}
