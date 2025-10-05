# Profit/Loss Calculator Page Implementation

## Overview

Created a Flutter implementation of the YieldWise profit/loss calculator that matches the HTML version's functionality while following the FarmOps app's design patterns and theme system.

## Features Implemented

### 📊 Calculator Inputs

- **Crop Selection**: Dropdown with 12 crops (Rice, Wheat, Cotton, Sugarcane, Soybean, Groundnut, Tomato, Onion, Potato, Garlic, Jowar, Tur)
- **Farm Details**: Area (acres), Expected Yield (quintals/acre)
- **Market Data**: Market Price (₹/quintal)
- **Cost Inputs**: Seed, Fertilizer, Pesticide, Labor, Other expenses
- **Loan Information**: Loan Amount, Interest Rate (optional)

### 🎯 Auto-fill Feature

- When user selects a crop, expected yield and market price are automatically populated based on average values
- User can override these values if needed

### 💰 Financial Analysis Output

- **Net Profit/Loss**: Clear display with color-coded indicator (green for profit, red for loss)
- **ROI Indicator**: Shows ROI percentage with quality rating (Excellent/Good/Low/High Risk)
- **Loan Analysis** (when applicable):
  - Loan Amount
  - Interest Rate
  - Annual Interest
  - Total Repayment
  - Monthly EMI
- **Key Metrics** (6-card grid):
  - Total Revenue
  - Operational Costs
  - Total Costs
  - Production (quintals)
  - Profit Margin (%)
  - Cost per Acre

### 💡 Smart Recommendations

Intelligent suggestions based on:

- **Loan Management**: Warnings for high loan burden, suggestions for government schemes
- **ROI Analysis**: Crop switching recommendations, cost optimization tips
- **Yield Comparison**: Advice on improving yields if below average
- **Price Optimization**: Marketing and value addition suggestions
- **Cost Analysis**: Identifies highest cost areas and suggests optimization
- **Financial Planning**: Reinvestment and diversification advice
- **Scale Recommendations**: Suggestions for small farms
- **Risk Management**: Crop insurance and diversification for volatile crops

## Design Consistency

### 🎨 Theme Support

- **Light Mode**:
  - Background: White
  - Primary Color: #008575 (Teal)
  - Light Green BG: #E2FCE1
  - Text: Black
- **Dark Mode**:
  - Background: #121212 (Dark Gray)
  - Primary Color: #00A890 (Light Teal)
  - Light Green BG: #1E3A35 (Dark Teal)
  - Text: White

### 📐 Layout Pattern (Following Soil Recommendation Page)

- ✅ Header with back button and "Farm-Ops" title in teal
- ✅ Icon + Title + Description card with light green background
- ✅ Two-column input layout for better space utilization
- ✅ Consistent dropdown and text field styling with bottom borders
- ✅ Full-width green action button
- ✅ Results displayed in styled cards below inputs
- ✅ Footer navigation with Profile (left), Home (center), Chatbot (right)

### 🔧 Theme Extensions Used

All colors use context extensions from `ThemeProvider`:

- `context.primaryColor` - Teal brand color
- `context.textColor` - Adaptive text color
- `context.secondaryTextColor` - Muted text
- `context.lightGreenBg` - Header/footer background
- `context.cardColor` - Card backgrounds
- `context.borderColor` - Input borders

## Navigation

- Route: `/profit-loss-calculator`
- Accessible from Home Page grid
- Integrated with existing navigation system

## File Structure

```
lib/
├── profit_loss_calculator_page.dart (NEW)
├── home_page.dart (UPDATED - added route)
├── services/
│   └── theme_provider.dart (existing)
└── assets/
    └── images/
        └── profitloss_calculator.png (existing)
```

## Usage

1. User taps "Profit/Loss Calculator" from home page
2. Selects crop type (auto-fills yield and price)
3. Enters farm area and cost details
4. Optionally enters loan information
5. Taps "Calculate Profit/Loss" button
6. Views financial analysis with profit/loss, ROI, and metrics
7. Reads smart recommendations tailored to their situation
8. Can navigate back via header button or footer home button

## Calculations

### Revenue

```dart
totalProduction = farmArea × expectedYield
totalRevenue = totalProduction × marketPrice
```

### Costs

```dart
operationalCosts = seedCost + fertilizerCost + pesticideCost + laborCost + otherCost
annualInterest = (loanAmount × interestRate) / 100
totalLoanRepayment = loanAmount + annualInterest
totalCosts = operationalCosts + totalLoanRepayment
```

### Profit Metrics

```dart
netProfit = totalRevenue - totalCosts
profitMargin = (netProfit / totalRevenue) × 100
roi = (netProfit / totalCosts) × 100
monthlyEMI = totalLoanRepayment / 12
```

## Testing Checklist

- [ ] Test in light mode - all colors visible
- [ ] Test in dark mode - all colors visible
- [ ] Verify crop auto-fill works for all 12 crops
- [ ] Test form validation (required fields)
- [ ] Verify profit calculation accuracy
- [ ] Verify loss calculation accuracy
- [ ] Test with loan (check EMI calculation)
- [ ] Test without loan (no loan section shown)
- [ ] Verify suggestions appear and are relevant
- [ ] Test footer navigation buttons
- [ ] Test back button navigation
- [ ] Verify scrolling works on small screens

## Comparison with HTML Version

### ✅ Feature Parity

- [x] All 12 crops supported
- [x] Same input fields
- [x] Auto-fill on crop selection
- [x] Loan calculation with EMI
- [x] ROI and profit margin calculations
- [x] Smart recommendations system
- [x] Responsive layout

### ✨ Improvements Over HTML

- Native Flutter performance
- Better form validation
- Consistent with app design language
- Integrated theme system (light/dark)
- Native navigation
- Better mobile UX with optimized layouts
- Cleaner, more maintainable code structure

## Next Steps

1. Run `flutter pub get` (if needed)
2. Test the page on both light and dark themes
3. Verify calculations with sample data
4. Test on different screen sizes
5. Consider adding data persistence for calculations
6. Consider adding export/share functionality for results
