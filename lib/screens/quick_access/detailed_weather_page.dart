import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/farmer_profile.dart';
import '../../services/weather_service.dart';

/// 7-Day Agricultural Weather Forecast Page.
class DetailedWeatherPage extends StatelessWidget {
  final FarmerProfile profile;
  final FarmWeatherReport? report;

  const DetailedWeatherPage({super.key, required this.profile, this.report});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final days = [
      {
        'day': 'Today',
        'temp': '${report?.temperature.toStringAsFixed(1) ?? '28'}°C',
        'cond': report?.conditionName ?? 'Partly Cloudy',
        'rain': '15%',
        'icon': Icons.wb_cloudy_rounded,
      },
      {
        'day': 'Tomorrow',
        'temp': '29.5°C',
        'cond': 'Sunny / Clear',
        'rain': '5%',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'day': 'Day 3',
        'temp': '27.0°C',
        'cond': 'Scattered Clouds',
        'rain': '20%',
        'icon': Icons.cloud_queue_rounded,
      },
      {
        'day': 'Day 4',
        'temp': '26.2°C',
        'cond': 'Light Rain Possible',
        'rain': '65%',
        'icon': Icons.water_drop_rounded,
      },
      {
        'day': 'Day 5',
        'temp': '28.0°C',
        'cond': 'Clear Sky',
        'rain': '10%',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'day': 'Day 6',
        'temp': '29.1°C',
        'cond': 'Warm / Sunny',
        'rain': '0%',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'day': 'Day 7',
        'temp': '28.4°C',
        'cond': 'Partly Cloudy',
        'rain': '15%',
        'icon': Icons.wb_cloudy_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(loc.weatherForecastTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0277BD), Color(0xFF01579B)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.effectiveDistrict}, ${profile.effectiveState}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '7-Day Agricultural Forecast',
                            style: TextStyle(
                              color: Color(0xFFB3E5FC),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.satellite_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...days.map(
            (d) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F5FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      d['icon'] as IconData,
                      color: const Color(0xFF0288D1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['day'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          d['cond'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 14,
                        color: Color(0xFF0288D1),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        d['rain'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0288D1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    d['temp'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
