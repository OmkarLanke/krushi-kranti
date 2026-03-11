package com.krushikranti.farmer.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * Response DTO for current weather data from WeatherAPI.com
 * 
 * This class maps the JSON response from WeatherAPI.com's current weather endpoint.
 * It includes location information and current weather conditions.
 * 
 * Implements Serializable to support Redis caching.
 * 
 * @author KrushiKranti Team
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeatherResponse implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * Location information for the weather data
     */
    private Location location;

    /**
     * Current weather conditions
     */
    private Current current;

    /**
     * Nested class for location details
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Location implements Serializable {
        private static final long serialVersionUID = 1L;

        private String name;           // Location name
        private String region;         // Region/state
        private String country;        // Country name
        private Double lat;            // Latitude
        private Double lon;            // Longitude
        
        @JsonProperty("tz_id")
        private String tzId;           // Timezone identifier
        
        @JsonProperty("localtime_epoch")
        private Long localtimeEpoch;   // Local time as epoch
        
        private String localtime;      // Local time as string (YYYY-MM-DD HH:mm)
    }

    /**
     * Nested class for current weather conditions
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Current implements Serializable {
        private static final long serialVersionUID = 1L;

        @JsonProperty("last_updated_epoch")
        private Long lastUpdatedEpoch;       // Last update time as epoch
        
        @JsonProperty("last_updated")
        private String lastUpdated;          // Last update time as string
        
        @JsonProperty("temp_c")
        private Double tempC;                // Temperature in Celsius
        
        @JsonProperty("temp_f")
        private Double tempF;                // Temperature in Fahrenheit
        
        @JsonProperty("is_day")
        private Integer isDay;               // 1 = day, 0 = night
        
        private Condition condition;         // Weather condition details
        
        @JsonProperty("wind_mph")
        private Double windMph;              // Wind speed in mph
        
        @JsonProperty("wind_kph")
        private Double windKph;              // Wind speed in kph
        
        @JsonProperty("wind_degree")
        private Integer windDegree;          // Wind direction in degrees
        
        @JsonProperty("wind_dir")
        private String windDir;              // Wind direction (N, S, E, W, etc.)
        
        @JsonProperty("pressure_mb")
        private Double pressureMb;           // Pressure in millibars
        
        @JsonProperty("pressure_in")
        private Double pressureIn;           // Pressure in inches
        
        @JsonProperty("precip_mm")
        private Double precipMm;             // Precipitation in mm
        
        @JsonProperty("precip_in")
        private Double precipIn;             // Precipitation in inches
        
        private Integer humidity;            // Humidity percentage
        
        private Integer cloud;               // Cloud cover percentage
        
        @JsonProperty("feelslike_c")
        private Double feelslikeC;           // Feels like temp in Celsius
        
        @JsonProperty("feelslike_f")
        private Double feelslikeF;           // Feels like temp in Fahrenheit
        
        @JsonProperty("vis_km")
        private Double visKm;                // Visibility in km
        
        @JsonProperty("vis_miles")
        private Double visMiles;             // Visibility in miles
        
        private Double uv;                   // UV index
        
        @JsonProperty("gust_mph")
        private Double gustMph;              // Wind gust in mph
        
        @JsonProperty("gust_kph")
        private Double gustKph;              // Wind gust in kph
    }

    /**
     * Nested class for weather condition information
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Condition implements Serializable {
        private static final long serialVersionUID = 1L;

        private String text;           // Weather condition text (e.g., "Sunny")
        private String icon;           // URL to weather icon
        private Integer code;          // Weather condition code
    }
}
