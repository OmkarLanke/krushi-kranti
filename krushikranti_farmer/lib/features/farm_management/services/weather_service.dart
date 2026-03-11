import '../../../core/services/http_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/weather_model.dart';

/// Service for fetching weather data from farmer-service
class WeatherService {
  /// Get current weather for a specific farm
  static Future<WeatherResponse?> getCurrentWeatherForFarm(int farmId) async {
    try {
      final response = await HttpService.get(
        ApiEndpoints.weatherFarmCurrent(farmId.toString()),
      );

      if (response != null && response['data'] != null) {
        return WeatherResponse.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching current weather for farm: $e');
      return null;
    }
  }

  /// Get weather forecast for a specific farm
  static Future<ForecastResponse?> getForecastForFarm(
    int farmId, {
    int days = 7,
  }) async {
    try {
      final response = await HttpService.get(
        ApiEndpoints.weatherFarmForecast(farmId.toString(), days),
      );

      if (response != null && response['data'] != null) {
        return ForecastResponse.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching forecast for farm: $e');
      return null;
    }
  }

  /// Get current weather for farmer's primary farm (first active farm)
  static Future<WeatherResponse?> getPrimaryFarmWeather() async {
    try {
      final response = await HttpService.get(
        ApiEndpoints.weatherPrimaryCurrent,
      );

      if (response != null && response['data'] != null) {
        return WeatherResponse.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching primary farm weather: $e');
      return null;
    }
  }

  /// Get weather forecast for farmer's primary farm
  static Future<ForecastResponse?> getPrimaryFarmForecast({
    int days = 7,
  }) async {
    try {
      final response = await HttpService.get(
        ApiEndpoints.weatherPrimaryForecast(days),
      );

      if (response != null && response['data'] != null) {
        return ForecastResponse.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching primary farm forecast: $e');
      return null;
    }
  }
}
