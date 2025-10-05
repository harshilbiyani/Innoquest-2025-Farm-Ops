import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class WeatherForecastPage extends StatefulWidget {
  const WeatherForecastPage({super.key});

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentWeather;
  List<dynamic>? _forecast;
  List<dynamic>? _alerts;

  // OpenWeather API Key
  final String _apiKey = '3f17cc8fc635e6b29600fb3de9e788fa';

  // Weather icon mapping
  final Map<String, String> _weatherIcons = {
    '01d': '☀️',
    '01n': '🌙',
    '02d': '⛅',
    '02n': '☁️',
    '03d': '☁️',
    '03n': '☁️',
    '04d': '☁️',
    '04n': '☁️',
    '09d': '🌧️',
    '09n': '🌧️',
    '10d': '🌦️',
    '10n': '🌧️',
    '11d': '⛈️',
    '11n': '⛈️',
    '13d': '🌨️',
    '13n': '🌨️',
    '50d': '🌫️',
    '50n': '🌫️',
  };

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    print('=== _getUserLocation called ===');
    try {
      // STEP 1: Try to get accurate GPS location from device
      print('Attempting to get GPS location...');
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
      } else {
        // Check for location permissions
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          print('Location permissions are permanently denied');
        }

        // If we have permission, get the position
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );

            print(
              'GPS Location obtained: ${position.latitude}, ${position.longitude}',
            );

            // Reverse geocode to get city name
            try {
              List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              );

              if (placemarks.isNotEmpty) {
                Placemark place = placemarks[0];
                String city =
                    place.locality ?? place.subAdministrativeArea ?? 'Unknown';
                String region = place.administrativeArea ?? '';
                String country = place.country ?? '';

                print('Reverse geocoded to: $city, $region, $country');

                if (mounted) {
                  setState(() {
                    String displayLocation = city;
                    if (region.isNotEmpty && region != city) {
                      displayLocation = '$city, $region';
                    }
                    _locationController.text =
                        '$displayLocation (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
                    print('Set GPS location to: ${_locationController.text}');
                  });
                }
                _getWeather();
                return;
              }
            } catch (geocodeError) {
              print('Reverse geocoding failed: $geocodeError');
              // Still use GPS coordinates even if reverse geocoding fails
              if (mounted) {
                setState(() {
                  _locationController.text =
                      'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
                });
              }
              _getWeather();
              return;
            }
          } catch (positionError) {
            print('Error getting GPS position: $positionError');
          }
        }
      }

      // STEP 2: Fallback to backend API (IP-based, less accurate)
      print('GPS unavailable, trying backend API...');
      try {
        final response = await http
            .get(Uri.parse('http://127.0.0.1:5000/api/get-location'))
            .timeout(const Duration(seconds: 5));

        print('Backend response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'success' && data['location'] != null) {
            final location = data['location'];
            final city = location['city'];
            final lat = location['latitude'];
            final lon = location['longitude'];
            final region = location['region'];

            print('Got location from backend - City: $city, Region: $region');
            print('Coordinates: Lat: $lat, Lon: $lon');

            // Only use backend location if it's not the default fallback
            if (city != null &&
                city != 'Unknown' &&
                city != 'New Delhi' &&
                data['note'] == null) {
              if (mounted) {
                setState(() {
                  String displayLocation = city;
                  if (region != null && region.isNotEmpty && region != city) {
                    displayLocation = '$city, $region';
                  }
                  _locationController.text =
                      '$displayLocation ($lat, $lon) [IP-based]';
                  print('Set IP location to: ${_locationController.text}');
                });
              }
              _getWeather();
              return;
            }
          }
        }
      } catch (backendError) {
        print('Backend not available: $backendError');
      }

      // STEP 3: Try direct IP geolocation as last resort
      print('Trying direct IP geolocation via ipapi.co...');
      try {
        final ipResponse = await http
            .get(Uri.parse('https://ipapi.co/json/'))
            .timeout(const Duration(seconds: 10));

        print('ipapi.co response status: ${ipResponse.statusCode}');

        if (ipResponse.statusCode == 200) {
          final ipData = json.decode(ipResponse.body);

          if (ipData['error'] != null) {
            print('ipapi.co error: ${ipData['error']}');
            throw Exception('Rate limit or API error');
          }

          if (ipData['city'] != null &&
              ipData['latitude'] != null &&
              ipData['longitude'] != null) {
            final city = ipData['city'];
            final region = ipData['region'];
            final lat = ipData['latitude'];
            final lon = ipData['longitude'];

            print('Got location from ipapi.co - City: $city, Region: $region');

            if (mounted) {
              setState(() {
                String displayLocation = city;
                if (region != null && region.isNotEmpty && region != city) {
                  displayLocation = '$city, $region';
                }
                _locationController.text =
                    '$displayLocation ($lat, $lon) [IP-based]';
                print('Set IP location to: ${_locationController.text}');
              });
            }
            _getWeather();
            return;
          }
        }
      } catch (ipError) {
        print('ipapi.co error: $ipError');
      }

      // Ultimate fallback: New Delhi
      print('All location services failed, using default location (New Delhi)');
      if (mounted) {
        setState(() {
          _locationController.text =
              'New Delhi, Delhi (28.6139, 77.2090) [Default]';
        });
      }
      _getWeather();
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        setState(() {
          _locationController.text =
              'New Delhi, Delhi (28.6139, 77.2090) [Default]';
        });
      }
      _getWeather();
    }
  }

  Future<void> _getWeather() async {
    print('=== _getWeather called ===');
    print('Location input: ${_locationController.text}');

    if (_locationController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a location';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentWeather = null;
      _forecast = null;
      _alerts = null;
    });

    try {
      String location = _locationController.text.trim();
      double lat, lon;
      String locationName;

      // Check if input contains coordinates in parentheses like "City (lat, lon)"
      if (location.contains('(') && location.contains(')')) {
        print('Input contains coordinates in parentheses');
        final cityPart = location.substring(0, location.indexOf('(')).trim();
        final coordsPart = location.substring(
          location.indexOf('(') + 1,
          location.indexOf(')'),
        );
        final parts = coordsPart.split(',');
        lat = double.parse(parts[0].trim());
        lon = double.parse(parts[1].trim());
        locationName = cityPart;
        print('Extracted: City=$cityPart, Lat=$lat, Lon=$lon');
      }
      // Check if input is just coordinates
      else if (location.contains(',') && !location.contains(' ')) {
        print('Input is coordinates');
        final parts = location.split(',');
        lat = double.parse(parts[0].trim());
        lon = double.parse(parts[1].trim());
        locationName = 'Current Location';
      } else {
        print('Input is city name, calling geocoding API');
        // Geocoding to get coordinates from city name
        final geoUrl =
            'http://api.openweathermap.org/geo/1.0/direct?q=$location&limit=1&appid=$_apiKey';
        print('Geocoding URL: $geoUrl');
        final geoResponse = await http.get(Uri.parse(geoUrl));
        print('Geocoding response: ${geoResponse.body}');
        final geoData = json.decode(geoResponse.body) as List;

        if (geoData.isEmpty) {
          throw Exception('Location not found');
        }

        lat = geoData[0]['lat'];
        lon = geoData[0]['lon'];
        locationName = '${geoData[0]['name']}, ${geoData[0]['country']}';
        print('Geocoded to: $locationName ($lat, $lon)');
      }

      print('Fetching current weather for $lat, $lon');
      // Get current weather
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final currentResponse = await http.get(Uri.parse(currentUrl));
      print('Current weather response status: ${currentResponse.statusCode}');
      final currentData = json.decode(currentResponse.body);

      print('Fetching forecast for $lat, $lon');
      // Get 5-day forecast
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));
      print('Forecast response status: ${forecastResponse.statusCode}');
      final forecastData = json.decode(forecastResponse.body);

      // Process current weather
      final sunrise = DateTime.fromMillisecondsSinceEpoch(
        currentData['sys']['sunrise'] * 1000,
      );
      final sunset = DateTime.fromMillisecondsSinceEpoch(
        currentData['sys']['sunset'] * 1000,
      );

      print('Processing weather data...');
      setState(() {
        _currentWeather = {
          'temp': currentData['main']['temp'],
          'feels_like': currentData['main']['feels_like'],
          'description': currentData['weather'][0]['description'],
          'icon': currentData['weather'][0]['icon'],
          'humidity': currentData['main']['humidity'],
          'pressure': currentData['main']['pressure'],
          'wind_speed': (currentData['wind']['speed'] * 3.6).toStringAsFixed(1),
          'visibility': ((currentData['visibility'] ?? 0) / 1000)
              .toStringAsFixed(1),
          'clouds': currentData['clouds']['all'],
          'sunrise':
              '${sunrise.hour.toString().padLeft(2, '0')}:${sunrise.minute.toString().padLeft(2, '0')}',
          'sunset':
              '${sunset.hour.toString().padLeft(2, '0')}:${sunset.minute.toString().padLeft(2, '0')}',
          'location': locationName,
        };

        // Process forecast
        _forecast = _processForecast(forecastData['list']);

        // Generate alerts
        _alerts = _generateAlerts(currentData, forecastData);

        _isLoading = false;
        print('Weather data loaded successfully!');
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch weather data: ${e.toString()}';
      });
    }
  }

  List<Map<String, dynamic>> _processForecast(List<dynamic> forecastList) {
    final processed = <Map<String, dynamic>>[];
    final processedDates = <String>{};

    for (var item in forecastList) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateStr = '${date.year}-${date.month}-${date.day}';

      if (!processedDates.contains(dateStr) && processed.length < 5) {
        final now = DateTime.now();
        String dayName;

        if (date.day == now.day && date.month == now.month) {
          dayName = 'Today';
        } else if (date.day == now.day + 1 && date.month == now.month) {
          dayName = 'Tomorrow';
        } else {
          dayName = _getDayName(date.weekday);
        }

        processed.add({
          'day': dayName,
          'temp_max': item['main']['temp_max'],
          'temp_min': item['main']['temp_min'],
          'description': item['weather'][0]['description'],
          'icon': item['weather'][0]['icon'],
        });

        processedDates.add(dateStr);
      }
    }

    return processed;
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  List<Map<String, String>> _generateAlerts(
    Map<String, dynamic> currentData,
    Map<String, dynamic> forecastData,
  ) {
    final alerts = <Map<String, String>>[];
    final temp = currentData['main']['temp'];
    final humidity = currentData['main']['humidity'];
    final windSpeed = currentData['wind']['speed'] * 3.6;

    // Extreme temperature alerts
    if (temp > 40) {
      alerts.add({
        'severity': 'severe',
        'title': 'Extreme Heat Warning',
        'description':
            'Temperature is ${temp.toStringAsFixed(1)}°C. Protect crops from heat stress. Increase irrigation.',
      });
    } else if (temp > 35) {
      alerts.add({
        'severity': 'warning',
        'title': 'High Temperature Alert',
        'description':
            'Temperature is ${temp.toStringAsFixed(1)}°C. Monitor crops for heat stress.',
      });
    } else if (temp < 0) {
      alerts.add({
        'severity': 'severe',
        'title': 'Frost Warning',
        'description':
            'Temperature is ${temp.toStringAsFixed(1)}°C. Protect crops from frost damage.',
      });
    } else if (temp < 5) {
      alerts.add({
        'severity': 'warning',
        'title': 'Cold Weather Alert',
        'description':
            'Temperature is ${temp.toStringAsFixed(1)}°C. Cold-sensitive crops may be affected.',
      });
    }

    // High humidity alert
    if (humidity > 80 && temp > 25) {
      alerts.add({
        'severity': 'warning',
        'title': 'High Humidity Alert',
        'description':
            'Humidity is $humidity%. Risk of fungal diseases. Monitor crops closely.',
      });
    }

    // Strong wind alert
    if (windSpeed > 50) {
      alerts.add({
        'severity': 'severe',
        'title': 'Strong Wind Warning',
        'description':
            'Wind speed is ${windSpeed.toStringAsFixed(1)} km/h. Secure loose items and protect crops.',
      });
    } else if (windSpeed > 30) {
      alerts.add({
        'severity': 'warning',
        'title': 'Moderate Wind Alert',
        'description':
            'Wind speed is ${windSpeed.toStringAsFixed(1)} km/h. Monitor crop conditions.',
      });
    }

    return alerts;
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
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.lightGreenBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/weather_forecast.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Weather Forecast',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Real-time weather updates and\nextreme weather alerts for farmers',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Location accuracy info banner
                    if (_locationController.text.contains('[IP-based]'))
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using IP-based location (less accurate). Enable GPS permissions for precise location.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Location input and buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _locationController,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: context.textColor,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Enter city name or coordinates (lat,lon)',
                              hintStyle: GoogleFonts.poppins(
                                color: context.secondaryTextColor,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: context.primaryColor,
                              ),
                            ),
                            onSubmitted: (_) => _getWeather(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _getWeather,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2BC24A),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Get Weather',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _getUserLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008575),
                                  padding: const EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick location buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildQuickLocationButton('Mumbai'),
                              _buildQuickLocationButton('Delhi'),
                              _buildQuickLocationButton('Bangalore'),
                              _buildQuickLocationButton('Pune'),
                              _buildQuickLocationButton('Kolkata'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Loading state
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: context.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Fetching weather data...',
                              style: GoogleFonts.poppins(
                                color: context.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ), // Error state
                    if (_errorMessage != null && !_isLoading)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Weather alerts
                    if (_alerts != null && _alerts!.isNotEmpty) ...[
                      ..._alerts!.map((alert) => _buildAlertCard(alert)),
                      const SizedBox(height: 16),
                    ],

                    // Current weather
                    if (_currentWeather != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main weather card
                          Expanded(child: _buildMainWeatherCard()),
                          const SizedBox(width: 16),
                          // Weather details card
                          Expanded(child: _buildWeatherDetailsCard()),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Forecast
                    if (_forecast != null) ...[
                      Text(
                        '5-Day Forecast',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._forecast!.map((day) => _buildForecastCard(day)),
                    ],

                    const SizedBox(height: 40),
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

  Widget _buildAlertCard(Map<String, String> alert) {
    Color borderColor;
    Color bgColor;
    IconData icon;

    switch (alert['severity']) {
      case 'severe':
        borderColor = Colors.red;
        bgColor = Colors.red[50]!;
        icon = Icons.warning;
        break;
      case 'warning':
        borderColor = Colors.orange;
        bgColor = Colors.orange[50]!;
        icon = Icons.warning_amber;
        break;
      default:
        borderColor = Colors.blue;
        bgColor = Colors.blue[50]!;
        icon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title']!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['description']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.primaryColor, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            _weatherIcons[_currentWeather!['icon']] ?? '🌤️',
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 12),
          Text(
            '${_currentWeather!['temp'].round()}°C',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: context.primaryColor,
            ),
          ),
          Text(
            _currentWeather!['description'].toString().toUpperCase()[0] +
                _currentWeather!['description'].toString().substring(1),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feels like ${_currentWeather!['feels_like'].round()}°C',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentWeather!['location'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.primaryColor, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('💧', 'Humidity', '${_currentWeather!['humidity']}%'),
          _buildDetailRow(
            '💨',
            'Wind',
            '${_currentWeather!['wind_speed']} km/h',
          ),
          _buildDetailRow(
            '🌡️',
            'Pressure',
            '${_currentWeather!['pressure']} hPa',
          ),
          _buildDetailRow(
            '👁️',
            'Visibility',
            '${_currentWeather!['visibility']} km',
          ),
          _buildDetailRow('☁️', 'Clouds', '${_currentWeather!['clouds']}%'),
          _buildDetailRow('🌅', 'Sunrise', _currentWeather!['sunrise']),
          _buildDetailRow('🌇', 'Sunset', _currentWeather!['sunset']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primaryColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day['day'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _weatherIcons[day['icon']] ?? '🌤️',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day['description'].toString().toUpperCase()[0] +
                      day['description'].toString().substring(1),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: context.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day['temp_max'].round()}°',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.secondaryTextColor,
                      ),
                    ),
                    Text(
                      '${day['temp_min'].round()}°',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLocationButton(String cityName) {
    return InkWell(
      onTap: () {
        setState(() {
          _locationController.text = cityName;
        });
        _getWeather();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.primaryColor),
        ),
        child: Text(
          cityName,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: context.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
