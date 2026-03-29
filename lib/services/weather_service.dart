import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temp;
  final int humidity;
  final String condition;
  final String description;
  final String icon;
  final double rainProbability;
  final String cityName;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.icon,
    this.rainProbability = 0.0,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    return WeatherData(
      temp: (json['main']['temp'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      condition: weather['main'] as String,
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      rainProbability: json['pop'] != null ? (json['pop'] as num).toDouble() : 0.0,
      cityName: json['name'] as String? ?? 'Chưa rõ',
    );
  }
}

class WeatherService {
  // NOTE: In production, user should provide their own OpenWeatherMap key
  static const String _apiKey = '60b861b5a9474ec9d2b59c1a013ed5bf'; 
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData?> fetchCurrentWeather({String language = 'vi'}) async {
    try {
      Position position = await _determinePosition();
      
      final url = Uri.parse(
        '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=$language'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
      return null;
    } catch (e) {
      if (e is! http.ClientException) {
        // ignore_for_file: avoid_print
        print('Error fetching weather: $e');
      }
      return null;
    }
  }

  Future<List<WeatherData>> fetchForecast({String language = 'vi'}) async {
    try {
      Position position = await _determinePosition();
      
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=$language'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['list'] as List;
        // Take first 5 segments (next 15 hours)
        return list.take(5).map((item) => WeatherData.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      // ignore_for_file: avoid_print
      print('Error fetching forecast: $e');
      return [];
    }
  }

  Future<Position> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackPosition();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackPosition();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return _fallbackPosition();
      } 

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      // Fallback for Flutter Web or MissingPluginException
      print('Location error: $e. Using fallback.');
      return _fallbackPosition();
    }
  }

  Position _fallbackPosition() {
    // Default to Hanoi, Vietnam if location is unavailable
    return Position(
      longitude: 105.8542,
      latitude: 21.0285,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
}
