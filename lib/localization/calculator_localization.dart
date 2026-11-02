/// Multilingual translations and formatting helpers for the KhetChacha Calculator Suite.
/// Supports Gujarati, Hindi, and English (plus fallbacks for all Indian locales).
class CalculatorLocalization {
  CalculatorLocalization._();

  /// Formats numbers to Indian Rupee (₹) currency format
  static String formatINR(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    String integerPart = parts[0];
    final decimalPart = parts[1];

    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      integerPart = '${buffer.toString()},$lastThree';
    }

    final formatted = decimalPart == '00'
        ? integerPart
        : '$integerPart.$decimalPart';
    return isNegative ? '-₹$formatted' : '₹$formatted';
  }

  /// Formats regular numbers (e.g. area, kg, bags) cleanly
  static String formatNumber(double value, {int maxDecimals = 2}) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    String str = value.toStringAsFixed(maxDecimals);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  static String t(String key, String langCode) {
    final table = _strings[key];
    if (table == null) return key;
    return table[langCode] ?? table['en'] ?? key;
  }

  static final Map<String, Map<String, String>> _strings = {
    // Dashboard Header
    'dashboard_title': {
      'en': 'Farm Calculators',
      'gu': 'ખેતી કેલ્ક્યુલેટર',
      'hi': 'कृषि कैलकुलेटर',
    },
    'dashboard_subtitle': {
      'en': 'Calculate smarter, farm better.',
      'gu': 'સ્માર્ટ ગણતરી કરો, શ્રેષ્ઠ ખેતી કરો.',
      'hi': 'स्मार्ट गणना करें, बेहतर खेती करें।',
    },
    'search_placeholder': {
      'en': 'Search calculators by name...',
      'gu': 'કેલ્ક્યુલેટર શોધો...',
      'hi': 'कैलकुलेटर खोजें...',
    },
    'no_results_found': {
      'en': 'No calculators match your search.',
      'gu': 'કોઈ મેળ ખાતું કેલ્ક્યુલેટર મળ્યું નથી.',
      'hi': 'कोई मिलता-जुलता कैलकुलेटर नहीं मिला।',
    },
    'calculate_action': {
      'en': 'Calculate',
      'gu': 'ગણતરી કરો',
      'hi': 'गणना करें',
    },
    'reset_action': {'en': 'Reset', 'gu': 'રીસેટ કરો', 'hi': 'रीसेट करें'},
    'calculate_again': {
      'en': 'Calculate Again',
      'gu': 'ફરીથી ગણતરી કરો',
      'hi': 'फिर से गणना करें',
    },
    'calculation_breakdown': {
      'en': 'Calculation Breakdown & Formula',
      'gu': 'ગણતરીની વિગત અને સૂત્ર',
      'hi': 'गणना का विवरण एवं सूत्र',
    },
    'results_title': {
      'en': 'Calculation Results',
      'gu': 'ગણતરીનું પરિણામ',
      'hi': 'गणना परिणाम',
    },
    'disclaimer_title': {
      'en': 'Important Note',
      'gu': 'મહત્વપૂર્ણ નોંધ',
      'hi': 'महत्वपूर्ण सूचना',
    },

    // Categories
    'cat_all': {
      'en': 'All Calculators',
      'gu': 'બધા કેલ્ક્યુલેટર',
      'hi': 'सभी कैलकुलेटर',
    },
    'cat_crop_fertilizer': {
      'en': 'Crop & Fertilizer',
      'gu': 'પાક અને ખાતર',
      'hi': 'फसल और उर्वरक',
    },
    'cat_farm_land': {
      'en': 'Farm & Land',
      'gu': 'ખેતર અને જમીન',
      'hi': 'खेत और जमीन',
    },
    'cat_cost_profit': {
      'en': 'Cost & Profit',
      'gu': 'ખર્ચ અને નફો',
      'hi': 'लागत और मुनाफा',
    },
    'cat_water_irrigation': {
      'en': 'Water & Irrigation',
      'gu': 'સિંચાઈ અને પાણી',
      'hi': 'सिंचाई और पानी',
    },

    // 1. Fertilizer Calculator
    'fertilizer_calc_name': {
      'en': 'Fertilizer Calculator',
      'gu': 'ખાતર કેલ્ક્યુલેટર',
      'hi': 'उर्वरक कैलकुलेटर',
    },
    'fertilizer_calc_desc': {
      'en': 'Calculate Urea, DAP, MOP bag requirements and nutrient doses for your field.',
      'gu': 'ખેતર માટે યુરિયા, ડીએપી, એમઓપી ખાતરની થેલીઓ અને માત્રા ગણો.',
      'hi': 'अपने खेत के लिए यूरिया, डीएपी, एमओपी खाद की बोरियों की सटीक गणना करें।',
    },
    'field_area': {
      'en': 'Field Area',
      'gu': 'ખેતરનું ક્ષેત્રફળ',
      'hi': 'खेत का क्षेत्रफल',
    },
    'area_unit': {'en': 'Area Unit', 'gu': 'માપ એકમ', 'hi': 'इकाई'},
    'crop_selection': {
      'en': 'Crop Name',
      'gu': 'પાકની પસંદગી',
      'hi': 'फसल का चयन',
    },
    'growth_stage': {
      'en': 'Growth Stage',
      'gu': 'પાકની અવસ્થા',
      'hi': 'फसल की अवस्था',
    },
    'fertilizer_type': {
      'en': 'Fertilizer Type',
      'gu': 'ખાતરનો પ્રકાર',
      'hi': 'उर्वरक का प्रकार',
    },
    'dose_required': {
      'en': 'Recommended Dose (kg/acre)',
      'gu': 'ભલામણ કરેલ માત્રા (કિગ્રા/એકર)',
      'hi': 'अनुशंसित मात्रा (किग्रा/एकड़)',
    },
    'bag_weight': {
      'en': 'Bag Weight (kg)',
      'gu': 'બેગનું વજન (કિગ્રા)',
      'hi': 'बोरी का वजन (किग्रा)',
    },
    'total_fertilizer': {
      'en': 'Total Fertilizer Needed',
      'gu': 'કુલ ખાતરની જરૂરિયાત',
      'hi': 'कुल आवश्यक उर्वरक',
    },
    'quantity_per_acre': {
      'en': 'Quantity per Acre',
      'gu': 'એકર દીઠ માત્રા',
      'hi': 'प्रति एकड़ मात्रा',
    },
    'full_bags_needed': {
      'en': 'Full Bags Required',
      'gu': 'જરૂરી આખી બેગ/થેલી',
      'hi': 'आवश्यक पूरी बोरियां',
    },
    'remaining_in_bag': {
      'en': 'Remaining in Final Bag',
      'gu': 'છેલ્લી બેગમાંથી બાકી કિગ્રા',
      'hi': 'अंतिम बोरी से शेष किग्रा',
    },

    // 2. Farmer Calculator
    'farmer_calc_name': {
      'en': 'Farmer General Calculator',
      'gu': 'ખેડૂત કેલ્ક્યુલેટર',
      'hi': 'किसान कैलकुलेटर',
    },
    'farmer_calc_desc': {
      'en': 'Quick all-in-one calculations for seeds, yields, costs, and profits.',
      'gu': 'બિયારણ, ઉત્પાદન, ખર્ચ અને નફા માટે સર્વગ્રાહી કેલ્ક્યુલેટર.',
      'hi': 'बीज, उपज, कुल लागत एवं मुनाफे की तुरंत आसान गणना।',
    },

    // 3. Land Area Calculator
    'land_calc_name': {
      'en': 'Land Area Calculator',
      'gu': 'જમીન માપ કેલ્ક્યુલેટર',
      'hi': 'भूमि क्षेत्रफल कैलकुलेटर',
    },
    'land_calc_desc': {
      'en': 'Convert between Acre, Hectare, Bigha, Guntha, Sq.Metre & Dimensions.',
      'gu': 'એકર, હેક્ટર, વીઘા, ગૂંઠા અને ચોરસ ફૂટ/મીટર વચ્ચે સચોટ રૂપાંતરણ.',
      'hi': 'एकड़, हेक्टेयर, बीघा, गुंठा और वर्ग मीटर/फुट का आसान रूपांतरण।',
    },
    'regional_bigha_factor': {
      'en': 'Regional Bigha Standard (Bigha / Acre)',
      'gu': 'પ્રાદેશિક વીઘા માપ (વીઘા પ્રતિ એકર)',
      'hi': 'क्षेत्रीय बीघा मानक (बीघा प्रति एकड़)',
    },

    // 4. Seed Calculator
    'seed_calc_name': {
      'en': 'Seed Calculator',
      'gu': 'બિયારણ કેલ્ક્યુલેટર',
      'hi': 'बीज कैलकुलेटर',
    },
    'seed_calc_desc': {
      'en':
          'Calculate exact seed requirement with optional germination buffer.',
      'gu': 'ખેતર માટે જરૂરી બિયારણ અને વધારાના અનામત જથ્થાની ગણતરી.',
      'hi': 'खेत के लिए आवश्यक सटीक बीज एवं रिजर्व प्रतिशत की गणना करें।',
    },
    'seed_rate': {
      'en': 'Seed Rate (kg/acre)',
      'gu': 'બિયારણનો દર (કિગ્રા/એકર)',
      'hi': 'बीज दर (किग्रा/एकड़)',
    },
    'seed_buffer': {
      'en': 'Germination / Extra Buffer (%)',
      'gu': 'વધારાનો અનામત જથ્થો (%)',
      'hi': 'अतिरिक्त बफर प्रतिशत (%)',
    },

    // 5. Crop Yield Calculator
    'yield_calc_name': {
      'en': 'Crop Yield Calculator',
      'gu': 'પાક ઉત્પાદન કેલ્ક્યુલેટર',
      'hi': 'फसल उपज कैलकुलेटर',
    },
    'yield_calc_desc': {
      'en': 'Estimate harvest quantity in Quintals, Tons, and Maunds/Mon.',
      'gu': 'કુલ અંદાજિત ઉત્પાદન ક્વિન્ટલ, ટન અને મણમાં ગણો.',
      'hi': 'अपेक्षित कुल उपज की क्विंटल, टन एवं मन में गणना करें।',
    },
    'expected_yield': {
      'en': 'Expected Yield per Acre',
      'gu': 'અપેક્ષિત એકર દીઠ ઉત્પાદન',
      'hi': 'अपेक्षित प्रति एकड़ उपज',
    },

    // 6. Cost & Profit Calculator
    'cost_profit_calc_name': {
      'en': 'Farming Cost & Profit Calculator',
      'gu': 'ખેતી ખર્ચ અને નફો કેલ્ક્યુલેટર',
      'hi': 'खेती लागत एवं मुनाफा कैलकुलेटर',
    },
    'cost_profit_calc_desc': {
      'en': 'Track seed, labor, fertilizer expenses, net revenue, and break-even selling price.',
      'gu': 'બિયારણ, મજૂરી, ખાતર ખર્ચ અને ચોખ્ખા નફાની વિસ્તૃત ગણતરી.',
      'hi': 'बीज, मजदूरी, खाद व्यय एवं शुद्ध लाभ व ब्रेक-इवन मूल्य की गणना।',
    },
    'total_expenses': {
      'en': 'Total Expenses',
      'gu': 'કુલ ખર્ચ',
      'hi': 'कुल खर्च',
    },
    'gross_revenue': {'en': 'Gross Revenue', 'gu': 'કુલ આવક', 'hi': 'सकल आय'},
    'net_profit': {
      'en': 'Net Profit / Loss',
      'gu': 'ચોખ્ખો નફો / નુકસાન',
      'hi': 'शुद्ध मुनाफा / हानि',
    },
    'break_even_price': {
      'en': 'Break-Even Selling Price',
      'gu': 'બ્રેક-ઇવન વેચાણ કિંમત (નો-નફો-નો-નુકસાન)',
      'hi': 'ब्रेक-ईवन बिक्री मूल्य (नो-लॉस मूल्य)',
    },

    // 7. Irrigation Water Calculator
    'irrigation_calc_name': {
      'en': 'Irrigation Water Calculator',
      'gu': 'સિંચાઈ પાણી કેલ્ક્યુલેટર',
      'hi': 'सिंचाई जल कैलकुलेटर',
    },
    'irrigation_calc_desc': {
      'en': 'Estimate water requirements in Litres and Cubic Metres (m³).',
      'gu': 'ખેતર માટે જરૂરી પાણી લીટર અને ઘન મીટરમાં ગણો.',
      'hi': 'खेत की सिंचाई के लिए आवश्यक पानी लीटर एवं घन मीटर में निकालें।',
    },
    'irrigation_depth': {
      'en': 'Irrigation Depth (mm)',
      'gu': 'સિંચાઈ ઊંડાઈ (મિમી)',
      'hi': 'सिंचाई की गहराई (मिमी)',
    },
    'irrigation_efficiency': {
      'en': 'Irrigation Efficiency (%)',
      'gu': 'સિંચાઈ પદ્ધતિ કાર્યક્ષમતા (%)',
      'hi': 'सिंचाई दक्षता (%)',
    },

    // 8. Pesticide Dilution Calculator
    'pesticide_calc_name': {
      'en': 'Pesticide Dilution Calculator',
      'gu': 'જંતુનાશક દવા કેલ્ક્યુલેટર',
      'hi': 'कीटनाशक घोल कैलकुलेटर',
    },
    'pesticide_calc_desc': {
      'en':
          'Calculate exact chemical and water proportions for knapsack tanks.',
      'gu': 'પંપ/ટાંકી દીઠ જંતુનાશક દવાનું ચોક્કસ પ્રમાણ ગણો.',
      'hi': 'स्प्रे पंप/टंकी के लिए सटीक कीटनाशक एवं पानी की मात्रा निकालें।',
    },
    'tank_capacity': {
      'en': 'Spray Tank Capacity (Litres)',
      'gu': 'સ્પ્રે પંપની ક્ષમતા (લીટર)',
      'hi': 'स्प्रे टैंक क्षमता (लीटर)',
    },
    'dose_per_litre': {
      'en': 'Dosage per Litre (ml or g)',
      'gu': 'લીટર દીઠ પ્રમાણ (મિલી અથવા ગ્રામ)',
      'hi': 'प्रति लीटर खुराक (मिली या ग्राम)',
    },
    'number_of_tanks': {
      'en': 'Number of Tanks / Pumps',
      'gu': 'પમ્પ/ટાંકીની સંખ્યા',
      'hi': 'टंकियों/पंपों की संख्या',
    },
    'pesticide_warning': {
      'en': 'Always read and strictly follow the CIB&RC approved product label, safety gears, and waiting period before spraying.',
      'gu': 'સ્પ્રે કરતા પહેલા હંમેશા પ્રોડક્ટ લેબલ પર આપેલી સૂચનાઓ, સુરક્ષા સાધનો અને પ્રતીક્ષા સમયગાળાનું પાલન કરો.',
      'hi': 'स्प्रे करने से पहले हमेशा उत्पाद लेबल पर दिए गए निर्देशों, सुरक्षा उपकरणों और प्रतीक्षा अवधि का पालन करें।',
    },
  };
}
