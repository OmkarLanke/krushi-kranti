package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.ForecastResponse;
import com.krushikranti.farmer.dto.WeatherResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

/**
 * Client service for calling WeatherAPI.com external API.
 * 
 * This service is responsible for making HTTP calls to WeatherAPI.com
 * using Spring WebClient. It handles the low-level API communication
 * and error handling.
 * 
 * API Documentation: https://www.weatherapi.com/docs/
 * 
 * @author KrushiKranti Team
 */
@Slf4j
@Service
public class WeatherApiClient {

    private final WebClient weatherWebClient;
    
    /**
     * WeatherAPI.com API key
     * Value is injected from application.yml
     * Get your free key from: https://www.weatherapi.com/signup.aspx
     */
    @Value("${weather.api.key}")
    private String apiKey;

    /**
     * Constructor with dependency injection
     * @param weatherWebClient WebClient configured for weather API
     */
    public WeatherApiClient(@Qualifier("weatherWebClient") WebClient weatherWebClient) {
        this.weatherWebClient = weatherWebClient;
    }

    /**
     * Fetch current weather for a specific location.
     * 
     * Makes a GET request to /current.json endpoint.
     * 
     * @param latitude Latitude of the location (decimal degrees)
     * @param longitude Longitude of the location (decimal degrees)
     * @return WeatherResponse containing current weather data
     * @throws RuntimeException if API call fails
     */
    public WeatherResponse getCurrentWeather(Double latitude, Double longitude) {
        log.info("Fetching current weather for coordinates: {},{}", latitude, longitude);
        
        // Format coordinates as "lat,lon" string required by API
        String location = String.format("%f,%f", latitude, longitude);
        
        try {
            WeatherResponse response = weatherWebClient
                    .get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/current.json")
                            .queryParam("key", apiKey)
                            .queryParam("q", location)
                            .queryParam("aqi", "no")  // Don't fetch air quality data
                            .build())
                    .retrieve()
                    .bodyToMono(WeatherResponse.class)
                    .block();  // Block to convert reactive to synchronous
            
            log.info("Successfully fetched current weather for {}", location);
            return response;
            
        } catch (WebClientResponseException e) {
            log.error("Weather API error: Status={}, Body={}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Failed to fetch current weather: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error fetching weather", e);
            throw new RuntimeException("Failed to fetch current weather: " + e.getMessage(), e);
        }
    }

    /**
     * Fetch weather forecast for a specific location.
     * 
     * Makes a GET request to /forecast.json endpoint.
     * Returns current weather + forecast for upcoming days + alerts.
     * 
     * @param latitude Latitude of the location (decimal degrees)
     * @param longitude Longitude of the location (decimal degrees)
     * @param days Number of forecast days (1-14 for free tier, max 14)
     * @return ForecastResponse containing forecast data
     * @throws RuntimeException if API call fails
     */
    public ForecastResponse getForecast(Double latitude, Double longitude, int days) {
        log.info("Fetching {}-day forecast for coordinates: {},{}", days, latitude, longitude);
        
        // Validate days parameter (API allows 1-14 days for free tier)
        if (days < 1 || days > 14) {
            throw new IllegalArgumentException("Days must be between 1 and 14 (inclusive)");
        }
        
        String location = String.format("%f,%f", latitude, longitude);
        
        try {
            ForecastResponse response = weatherWebClient
                    .get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/forecast.json")
                            .queryParam("key", apiKey)
                            .queryParam("q", location)
                            .queryParam("days", days)
                            .queryParam("aqi", "no")  // Don't fetch air quality data
                            .queryParam("alerts", "yes")  // Include weather alerts
                            .build())
                    .retrieve()
                    .bodyToMono(ForecastResponse.class)
                    .block();
            
            log.info("Successfully fetched {}-day forecast for {}", days, location);
            return response;
            
        } catch (WebClientResponseException e) {
            log.error("Weather API error: Status={}, Body={}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Failed to fetch forecast: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error fetching forecast", e);
            throw new RuntimeException("Failed to fetch forecast: " + e.getMessage(), e);
        }
    }

    /**
     * Fetch astronomy data (sunrise, sunset, moon phases) for a specific location.
     * 
     * Makes a GET request to /astronomy.json endpoint.
     * Useful for farmers who need to plan activities based on daylight.
     * 
     * @param latitude Latitude of the location (decimal degrees)
     * @param longitude Longitude of the location (decimal degrees)
     * @param date Date in format yyyy-MM-dd (optional, defaults to today)
     * @return Astronomy data as generic object (can be typed later if needed)
     * @throws RuntimeException if API call fails
     */
    public Object getAstronomy(Double latitude, Double longitude, String date) {
        log.info("Fetching astronomy data for coordinates: {},{} on date: {}", latitude, longitude, date);
        
        String location = String.format("%f,%f", latitude, longitude);
        
        try {
            Object response = weatherWebClient
                    .get()
                    .uri(uriBuilder -> {
                        var builder = uriBuilder
                                .path("/astronomy.json")
                                .queryParam("key", apiKey)
                                .queryParam("q", location);
                        
                        if (date != null && !date.isEmpty()) {
                            builder.queryParam("dt", date);
                        }
                        
                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(Object.class)
                    .block();
            
            log.info("Successfully fetched astronomy data for {}", location);
            return response;
            
        } catch (WebClientResponseException e) {
            log.error("Weather API error: Status={}, Body={}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Failed to fetch astronomy data: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error fetching astronomy data", e);
            throw new RuntimeException("Failed to fetch astronomy data: " + e.getMessage(), e);
        }
    }
}
