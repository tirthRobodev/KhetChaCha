import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../localization/location_data.dart';

/// Real-time Agricultural Weather Report for KhetChacha.
class FarmWeatherReport {
  final double temperature;
  final double tempMax;
  final double tempMin;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final String conditionName;
  final String advisory;
  final String district;
  final String state;
  final DateTime lastUpdated;
  final bool isLive;

  const FarmWeatherReport({
    required this.temperature,
    required this.tempMax,
    required this.tempMin,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.conditionName,
    required this.advisory,
    required this.district,
    required this.state,
    required this.lastUpdated,
    this.isLive = true,
  });
}

/// Service to fetch live, accurate, real-time weather forecasts
/// for any Indian District & State using the Open-Meteo API.
class WeatherService {
  WeatherService._internal();
  static final WeatherService instance = WeatherService._internal();

  /// Fetches real-time live weather for [district] and [state] in [langCode] language.
  Future<FarmWeatherReport> getLiveWeather({
    required String district,
    required String state,
    String langCode = 'gu',
  }) async {
    final coords = LocationData.getCoordinates(district: district, state: state);

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=${coords.lat}&longitude=${coords.lon}&'
        'current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&'
        'daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&'
        'timezone=auto',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final daily = data['daily'] as Map<String, dynamic>? ?? {};

        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 29.0;
        final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 45;
        final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
        final code = (current['weather_code'] as num?)?.toInt() ?? 0;

        final maxList = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
        final minList = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
        final rainList = (daily['precipitation_probability_max'] as List<dynamic>?) ?? [];

        final tempMax = maxList.isNotEmpty ? (maxList[0] as num).toDouble() : temp + 4;
        final tempMin = minList.isNotEmpty ? (minList[0] as num).toDouble() : temp - 5;
        final rainProb = rainList.isNotEmpty ? (rainList[0] as num).toInt() : 0;

        final condition = _getConditionText(code, langCode);
        final advisory = _getAgriculturalAdvisory(
          temp: temp,
          humidity: humidity,
          windSpeed: wind,
          weatherCode: code,
          rainProb: rainProb,
          langCode: langCode,
        );

        return FarmWeatherReport(
          temperature: temp,
          tempMax: tempMax,
          tempMin: tempMin,
          humidity: humidity,
          windSpeed: wind,
          weatherCode: code,
          conditionName: condition,
          advisory: advisory,
          district: district,
          state: state,
          lastUpdated: DateTime.now(),
          isLive: true,
        );
      }
    } catch (e) {
      debugPrint('[WeatherService] Live fetch error: $e');
    }

    // High quality offline fallback tailored to Indian climate
    return _buildRealisticFallback(district: district, state: state, langCode: langCode);
  }

  /// Translates WMO weather codes into localized descriptive text
  String _getConditionText(int code, String langCode) {
    switch (code) {
      case 0:
        return _trans(langCode, 'Clear Sky / Sunny', 'ચોખ્ખું આકાશ / તડકો', 'साफ आसमान / धूप');
      case 1:
      case 2:
        return _trans(langCode, 'Partly Cloudy', 'આંશિક વાદળછાયું', 'आंशिक बादल');
      case 3:
        return _trans(langCode, 'Overcast / Cloudy', 'વાદળછાયું વાતાવરણ', 'बादलमय मौसम');
      case 45:
      case 48:
        return _trans(langCode, 'Foggy / Mist', 'ઝાકળ / ધુમ્મસ', 'कोहरा / धुंध');
      case 51:
      case 53:
      case 55:
        return _trans(langCode, 'Light Drizzle', 'હળવી ઝરમર', 'हल्की बूंदाबांदी');
      case 61:
      case 63:
      case 65:
        return _trans(langCode, 'Rain Shower', 'વરસાદ', 'वर्षा / बारिश');
      case 80:
      case 81:
      case 82:
        return _trans(langCode, 'Heavy Rain', 'ભારે વરસાદ', 'भारी बारिश');
      case 95:
      case 96:
      case 99:
        return _trans(langCode, 'Thunderstorm', 'ગાજવીજ સાથે વાવાઝોડું', 'आंधी-तूफान के साथ बारिश');
      default:
        return _trans(langCode, 'Clear Weather', 'અનુકૂળ હવામાન', 'अनुकूल मौसम');
    }
  }

  /// Generates practical, localized farming guidance based on live weather data
  String _getAgriculturalAdvisory({
    required double temp,
    required int humidity,
    required double windSpeed,
    required int weatherCode,
    required int rainProb,
    required String langCode,
  }) {
    if (weatherCode >= 61 || rainProb > 50) {
      return _trans(
        langCode,
        'Rain predicted today ($rainProb%). Avoid spraying pesticides and fertilizers. Ensure good drainage in fields.',
        'આજે વરસાદની શક્યતા ($rainProb%) છે. દવાનો છંટકાવ અને ખાતર આપવાનું ટાળો. ખેતરમાં પાણી ન ભરાય તેનું ધ્યાન રાખો.',
        'आज बारिश की संभावना ($rainProb%) है। कीटनाशक छिड़काव व खाद न डालें। खेतों में जल निकासी की व्यवस्था रखें।',
      );
    }

    if (temp > 36.0) {
      return _trans(
        langCode,
        'High temperature (${temp.toStringAsFixed(1)}°C). Irrigate crops during early morning or late evening to reduce water evaporation.',
        'ઊંચું તાપમાન (${temp.toStringAsFixed(1)}°C) છે. બાષ્પીભવન અટકાવવા સવારે અથવા સાંજના સમયે પિયત આપવું.',
        'तापमान अधिक (${temp.toStringAsFixed(1)}°C) है। वाष्पीकरण रोकने के लिए सुबह या शाम को सिंचाई करें।',
      );
    }

    if (humidity > 70) {
      return _trans(
        langCode,
        'High humidity ($humidity%). Check crops for fungal infections or pest infestation. Proper field ventilation needed.',
        'હવામાં ભેજ વધારે ($humidity%) છે. પાકમાં ફૂગ અને જીવાતનો ઉપદ્રવ ચકાસવો. પાકની યોગ્ય દેખરેખ રાખો.',
        'हवा में नमी अधिक ($humidity%) है। फसलों में फफूंद या कीटों के प्रकोप पर नजर रखें।',
      );
    }

    if (windSpeed > 25.0) {
      return _trans(
        langCode,
        'Strong wind (${windSpeed.toStringAsFixed(1)} km/h). Avoid aerial pesticide spraying and support tall crops like banana or papaya.',
        'તેજ પવન (${windSpeed.toStringAsFixed(1)} km/h) ફૂંકાઈ રહ્યો છે. સ્પ્રે કરવાનું ટાળો અને ઊંચા પાકોને ટેકો આપો.',
        'तेज हवाएं (${windSpeed.toStringAsFixed(1)} km/h) चल रही हैं। छिड़काव न करें व ऊंची फसलों को सहारा दें।',
      );
    }

    return _trans(
      langCode,
      'Favorable sunny weather. Excellent time for harvesting, field weeding, soil preparation, and crop drying.',
      'હવામાન ખેતી માટે અનુકૂળ છે. નિંદામણ, ખેત ખેડ, આંતરખેડ અને પાકની લણણી માટે ઉત્તમ સમય છે.',
      'मौसम खेती के लिए अनुकूल है। निराई-गुड़ाई, खेत की जुताई और फसल कटाई के लिए बेहतरीन समय है।',
    );
  }

  String _trans(String langCode, String en, String gu, String hi) {
    switch (langCode.toLowerCase()) {
      case 'gu':
        return gu;
      case 'hi':
        return hi;
      default:
        return en;
    }
  }

  FarmWeatherReport _buildRealisticFallback({
    required String district,
    required String state,
    required String langCode,
  }) {
    return FarmWeatherReport(
      temperature: 31.5,
      tempMax: 35.0,
      tempMin: 22.0,
      humidity: 38,
      windSpeed: 11.2,
      weatherCode: 1,
      conditionName: _trans(langCode, 'Clear Sunny Sky', 'તડકો અને ચોખ્ખું આકાશ', 'धूप और साफ आसमान'),
      advisory: _trans(
        langCode,
        'Favorable agricultural weather. Ideal for farm work and soil moisture maintenance.',
        'ખેતીકામ માટે અનુકૂળ હવામાન. પિયત અને ખાતર વ્યવસ્થાપન માટે શ્રેષ્ઠ સમય.',
        'कृषि कार्यों के लिए अनुकूल मौसम। सिंचाई और फसल देखभाल के लिए उपयुक्त समय।',
      ),
      district: district,
      state: state,
      lastUpdated: DateTime.now(),
      isLive: false,
    );
  }
}
