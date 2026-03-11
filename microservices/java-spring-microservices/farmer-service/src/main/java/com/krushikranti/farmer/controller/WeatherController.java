package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.ForecastResponse;
import com.krushikranti.farmer.dto.WeatherResponse;
import com.krushikranti.farmer.service.WeatherService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for Weather operations.
 * 
 * Provides weather data for farms based on GPS coordinates.
 * All endpoints are protected and require JWT token via API Gateway.
 * The API Gateway validates the token and forwards the userId in X-User-Id header.
 * 
 * Endpoints:
 * - GET /farmer/weather/farm/{farmId}/current - Current weather for specific farm
 * - GET /farmer/weather/farm/{farmId}/forecast - Forecast for specific farm
 * - GET /farmer/weather/primary/current - Current weather for primary farm
 * - GET /farmer/weather/primary/forecast - Forecast for primary farm
 * 
 * @author KrushiKranti Team
 */
@RestController
@RequestMapping("/farmer/weather")
@RequiredArgsConstructor
@Slf4j
public class WeatherController {

    private final WeatherService weatherService;

    /**
     * Get current weather for a specific farm.
     * 
     * Endpoint: GET /farmer/weather/farm/{farmId}/current
     * 
     * Example Response:
     * {
     *   "message": "Current weather retrieved successfully",
     *   "data": {
     *     "location": { "name": "Pune", "lat": 18.52, "lon": 73.85 },
     *     "current": {
     *       "temp_c": 28.5,
     *       "condition": { "text": "Partly cloudy" },
     *       "humidity": 65,
     *       "wind_kph": 12.5,
     *       "precip_mm": 0.0
     *     }
     *   }
     * }
     * 
     * @param userIdHeader User ID from JWT token (injected by API Gateway)
     * @param farmId ID of the farm
     * @return Current weather data
     */
    @GetMapping("/farm/{farmId}/current")
    public ResponseEntity<ApiResponse<WeatherResponse>> getCurrentWeatherForFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.info("GET /farmer/weather/farm/{}/current - userId: {}", farmId, userId);
        
        try {
            WeatherResponse weather = weatherService.getCurrentWeatherForFarm(farmId, userId);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    "Current weather retrieved successfully",
                    weather));
                    
        } catch (IllegalArgumentException e) {
            log.warn("Bad request for farmId {}: {}", farmId, e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(e.getMessage(), null));
                    
        } catch (Exception e) {
            log.error("Error fetching current weather for farmId {}", farmId, e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("Failed to fetch weather data", null));
        }
    }

    /**
     * Get weather forecast for a specific farm.
     * 
     * Endpoint: GET /farmer/weather/farm/{farmId}/forecast
     * Query Parameter: days (optional, default=7, max=14)
     * 
     * Example: GET /farmer/weather/farm/123/forecast?days=5
     * 
     * Example Response:
     * {
     *   "message": "Weather forecast retrieved successfully",
     *   "data": {
     *     "location": { "name": "Pune", "lat": 18.52, "lon": 73.85 },
     *     "current": { ... },
     *     "forecast": {
     *       "forecastday": [
     *         {
     *           "date": "2024-01-15",
     *           "day": {
     *             "maxtemp_c": 32.0,
     *             "mintemp_c": 18.0,
     *             "daily_chance_of_rain": 20,
     *             "totalprecip_mm": 0.5
     *           },
     *           "astro": {
     *             "sunrise": "06:45 AM",
     *             "sunset": "06:15 PM"
     *           }
     *         }
     *       ]
     *     },
     *     "alerts": { ... }
     *   }
     * }
     * 
     * @param userIdHeader User ID from JWT token
     * @param farmId ID of the farm
     * @param days Number of forecast days (1-14, default 7)
     * @return Weather forecast data
     */
    @GetMapping("/farm/{farmId}/forecast")
    public ResponseEntity<ApiResponse<ForecastResponse>> getForecastForFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "7") int days) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.info("GET /farmer/weather/farm/{}/forecast?days={} - userId: {}", farmId, days, userId);
        
        try {
            // Validate days parameter
            if (days < 1 || days > 14) {
                return ResponseEntity
                        .status(HttpStatus.BAD_REQUEST)
                        .body(new ApiResponse<>("Days must be between 1 and 14", null));
            }
            
            ForecastResponse forecast = weatherService.getForecastForFarm(farmId, userId, days);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    "Weather forecast retrieved successfully",
                    forecast));
                    
        } catch (IllegalArgumentException e) {
            log.warn("Bad request for farmId {}: {}", farmId, e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(e.getMessage(), null));
                    
        } catch (Exception e) {
            log.error("Error fetching forecast for farmId {}", farmId, e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("Failed to fetch forecast data", null));
        }
    }

    /**
     * Get current weather for farmer's primary farm (first active farm).
     * 
     * Endpoint: GET /farmer/weather/primary/current
     * 
     * This is a convenience endpoint for quick weather access.
     * Used in dashboard or home screen of farmer app.
     * 
     * @param userIdHeader User ID from JWT token
     * @return Current weather data for primary farm
     */
    @GetMapping("/primary/current")
    public ResponseEntity<ApiResponse<WeatherResponse>> getCurrentWeatherForPrimaryFarm(
            @RequestHeader("X-User-Id") String userIdHeader) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.info("GET /farmer/weather/primary/current - userId: {}", userId);
        
        try {
            WeatherResponse weather = weatherService.getCurrentWeatherForPrimaryFarm(userId);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    "Current weather retrieved successfully",
                    weather));
                    
        } catch (IllegalArgumentException e) {
            log.warn("Bad request for userId {}: {}", userId, e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(e.getMessage(), null));
                    
        } catch (Exception e) {
            log.error("Error fetching current weather for primary farm, userId {}", userId, e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("Failed to fetch weather data", null));
        }
    }

    /**
     * Get weather forecast for farmer's primary farm.
     * 
     * Endpoint: GET /farmer/weather/primary/forecast
     * Query Parameter: days (optional, default=7, max=14)
     * 
     * Example: GET /farmer/weather/primary/forecast?days=3
     * 
     * @param userIdHeader User ID from JWT token
     * @param days Number of forecast days (1-14, default 7)
     * @return Weather forecast data for primary farm
     */
    @GetMapping("/primary/forecast")
    public ResponseEntity<ApiResponse<ForecastResponse>> getForecastForPrimaryFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @RequestParam(defaultValue = "7") int days) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.info("GET /farmer/weather/primary/forecast?days={} - userId: {}", days, userId);
        
        try {
            // Validate days parameter
            if (days < 1 || days > 14) {
                return ResponseEntity
                        .status(HttpStatus.BAD_REQUEST)
                        .body(new ApiResponse<>("Days must be between 1 and 14", null));
            }
            
            ForecastResponse forecast = weatherService.getForecastForPrimaryFarm(userId, days);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    "Weather forecast retrieved successfully",
                    forecast));
                    
        } catch (IllegalArgumentException e) {
            log.warn("Bad request for userId {}: {}", userId, e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(new ApiResponse<>(e.getMessage(), null));
                    
        } catch (Exception e) {
            log.error("Error fetching forecast for primary farm, userId {}", userId, e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("Failed to fetch forecast data", null));
        }
    }
}
