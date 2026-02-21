package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.ForecastResponse;
import com.krushikranti.farmer.dto.WeatherResponse;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmRepository;
import com.krushikranti.farmer.repository.FarmerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * Business logic service for weather operations.
 * 
 * This service provides weather data for farms by:
 * 1. Fetching farm details from database
 * 2. Extracting GPS coordinates
 * 3. Calling WeatherAPI through WeatherApiClient
 * 4. Caching results to reduce API calls (30 minutes TTL)
 * 
 * Caching Strategy:
 * - Current weather: Cached for 30 minutes per location
 * - Forecast: Cached for 30 minutes per location
 * - Cache key includes coordinates to avoid conflicts
 * 
 * @author KrushiKranti Team
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WeatherService {

    private final WeatherApiClient weatherApiClient;
    private final FarmRepository farmRepository;
    private final FarmerRepository farmerRepository;

    /**
     * Get current weather for a specific farm by farm ID.
     * 
     * Flow:
     * 1. Fetch farm from database by farmId and userId (for security)
     * 2. Validate GPS coordinates exist
     * 3. Call weather API with coordinates
     * 4. Return weather data
     * 
     * @param farmId ID of the farm
     * @param userId ID of the authenticated user (farmer)
     * @return Current weather data for the farm location
     * @throws IllegalArgumentException if farm not found or coordinates missing
     */
    @Transactional(readOnly = true)
    public WeatherResponse getCurrentWeatherForFarm(Long farmId, Long userId) {
        log.info("Fetching current weather for farmId: {}, userId: {}", farmId, userId);
        
        // Find the farmer by userId
        Farmer farmer = farmerRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Farmer not found for userId: " + userId));
        
        // Find the farm by farmId and ensure it belongs to this farmer
        Farm farm = farmRepository.findByIdAndFarmerId(farmId, farmer.getId())
                .orElseThrow(() -> new IllegalArgumentException(
                    "Farm not found or does not belong to this farmer. FarmId: " + farmId));
        
        // Validate GPS coordinates are present
        if (farm.getFarmLatitude() == null || farm.getFarmLongitude() == null) {
            throw new IllegalArgumentException(
                "GPS coordinates not available for this farm. Please update farm location first.");
        }
        
        // Convert BigDecimal to Double for API call
        Double latitude = farm.getFarmLatitude().doubleValue();
        Double longitude = farm.getFarmLongitude().doubleValue();
        
        log.debug("Using coordinates: lat={}, lon={} for farm: {}", latitude, longitude, farm.getFarmName());
        
        // Fetch current weather (with caching)
        return getCurrentWeatherByCoordinates(latitude, longitude);
    }

    /**
     * Get current weather for farmer's primary farm.
     * 
     * Primary farm is the first active farm of the farmer.
     * This is a convenience method for quick weather access.
     * 
     * @param userId ID of the authenticated user (farmer)
     * @return Current weather data for primary farm location
     * @throws IllegalArgumentException if no active farm found
     */
    @Transactional(readOnly = true)
    public WeatherResponse getCurrentWeatherForPrimaryFarm(Long userId) {
        log.info("Fetching current weather for primary farm of userId: {}", userId);
        
        Farmer farmer = farmerRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Farmer not found for userId: " + userId));
        
        // Get first active farm (primary farm)
        List<Farm> activeFarms = farmRepository.findByFarmerIdAndIsActiveTrue(farmer.getId());
        
        if (activeFarms.isEmpty()) {
            throw new IllegalArgumentException("No active farms found for this farmer");
        }
        
        Farm primaryFarm = activeFarms.get(0);
        
        if (primaryFarm.getFarmLatitude() == null || primaryFarm.getFarmLongitude() == null) {
            throw new IllegalArgumentException(
                "GPS coordinates not available for primary farm. Please update farm location first.");
        }
        
        Double latitude = primaryFarm.getFarmLatitude().doubleValue();
        Double longitude = primaryFarm.getFarmLongitude().doubleValue();
        
        log.debug("Using primary farm: {} at coordinates: lat={}, lon={}", 
                primaryFarm.getFarmName(), latitude, longitude);
        
        return getCurrentWeatherByCoordinates(latitude, longitude);
    }

    /**
     * Get weather forecast for a specific farm.
     * 
     * Returns multi-day forecast including:
     * - Daily weather summary (max/min temp, precipitation, etc.)
     * - Hourly forecast for each day
     * - Astronomy data (sunrise, sunset, moon phases)
     * - Weather alerts (storms, droughts, etc.)
     * 
     * @param farmId ID of the farm
     * @param userId ID of the authenticated user (farmer)
     * @param days Number of forecast days (1-14, default 7)
     * @return Weather forecast data
     * @throws IllegalArgumentException if farm not found or coordinates missing
     */
    @Transactional(readOnly = true)
    public ForecastResponse getForecastForFarm(Long farmId, Long userId, int days) {
        log.info("Fetching {}-day forecast for farmId: {}, userId: {}", days, farmId, userId);
        
        Farmer farmer = farmerRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Farmer not found for userId: " + userId));
        
        Farm farm = farmRepository.findByIdAndFarmerId(farmId, farmer.getId())
                .orElseThrow(() -> new IllegalArgumentException(
                    "Farm not found or does not belong to this farmer. FarmId: " + farmId));
        
        if (farm.getFarmLatitude() == null || farm.getFarmLongitude() == null) {
            throw new IllegalArgumentException(
                "GPS coordinates not available for this farm. Please update farm location first.");
        }
        
        Double latitude = farm.getFarmLatitude().doubleValue();
        Double longitude = farm.getFarmLongitude().doubleValue();
        
        log.debug("Using coordinates: lat={}, lon={} for forecast", latitude, longitude);
        
        return getForecastByCoordinates(latitude, longitude, days);
    }

    /**
     * Get weather forecast for farmer's primary farm.
     * 
     * @param userId ID of the authenticated user (farmer)
     * @param days Number of forecast days (1-14, default 7)
     * @return Weather forecast data
     * @throws IllegalArgumentException if no active farm found
     */
    @Transactional(readOnly = true)
    public ForecastResponse getForecastForPrimaryFarm(Long userId, int days) {
        log.info("Fetching {}-day forecast for primary farm of userId: {}", days, userId);
        
        Farmer farmer = farmerRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Farmer not found for userId: " + userId));
        
        List<Farm> activeFarms = farmRepository.findByFarmerIdAndIsActiveTrue(farmer.getId());
        
        if (activeFarms.isEmpty()) {
            throw new IllegalArgumentException("No active farms found for this farmer");
        }
        
        Farm primaryFarm = activeFarms.get(0);
        
        if (primaryFarm.getFarmLatitude() == null || primaryFarm.getFarmLongitude() == null) {
            throw new IllegalArgumentException(
                "GPS coordinates not available for primary farm. Please update farm location first.");
        }
        
        Double latitude = primaryFarm.getFarmLatitude().doubleValue();
        Double longitude = primaryFarm.getFarmLongitude().doubleValue();
        
        log.debug("Using primary farm: {} for forecast", primaryFarm.getFarmName());
        
        return getForecastByCoordinates(latitude, longitude, days);
    }

    /**
     * Internal method to fetch current weather by coordinates with caching.
     * 
     * Cache key includes both lat and lon to avoid conflicts.
     * Cache TTL is 30 minutes (configured in application.yml or default).
     * 
     * Why caching?
     * - Reduces API calls (free tier has 1M calls/month limit)
     * - Improves response time for repeated requests
     * - Weather doesn't change significantly in 30 minutes
     * 
     * @param latitude Location latitude
     * @param longitude Location longitude
     * @return Current weather data
     */
    @Cacheable(value = "currentWeather", key = "#latitude + '_' + #longitude")
    protected WeatherResponse getCurrentWeatherByCoordinates(Double latitude, Double longitude) {
        log.info("Cache miss - Fetching fresh current weather data from API");
        return weatherApiClient.getCurrentWeather(latitude, longitude);
    }

    /**
     * Internal method to fetch forecast by coordinates with caching.
     * 
     * Cache key includes lat, lon, and days to handle different forecast ranges.
     * 
     * @param latitude Location latitude
     * @param longitude Location longitude
     * @param days Number of forecast days
     * @return Weather forecast data
     */
    @Cacheable(value = "weatherForecast", key = "#latitude + '_' + #longitude + '_' + #days")
    protected ForecastResponse getForecastByCoordinates(Double latitude, Double longitude, int days) {
        log.info("Cache miss - Fetching fresh {}-day forecast data from API", days);
        return weatherApiClient.getForecast(latitude, longitude, days);
    }
}
