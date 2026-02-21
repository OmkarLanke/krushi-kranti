package com.krushikranti.farmer.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.List;

/**
 * Response DTO for weather forecast data from WeatherAPI.com
 * 
 * This class maps the JSON response from WeatherAPI.com's forecast endpoint.
 * It includes current conditions plus forecast for upcoming days.
 * 
 * Implements Serializable to support Redis caching.
 * 
 * @author KrushiKranti Team
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ForecastResponse implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * Location information
     */
    private WeatherResponse.Location location;

    /**
     * Current weather conditions
     */
    private WeatherResponse.Current current;

    /**
     * Forecast data for upcoming days
     */
    private Forecast forecast;

    /**
     * Weather alerts if any (droughts, storms, etc.)
     */
    private Alerts alerts;

    /**
     * Nested class for forecast information
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Forecast implements Serializable {
        private static final long serialVersionUID = 1L;

        @JsonProperty("forecastday")
        private List<ForecastDay> forecastday;  // List of forecast days
    }

    /**
     * Nested class for each forecast day
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ForecastDay implements Serializable {
        private static final long serialVersionUID = 1L;

        private String date;                    // Date (YYYY-MM-DD)
        
        @JsonProperty("date_epoch")
        private Long dateEpoch;                 // Date as epoch
        
        private Day day;                        // Day weather summary
        
        private Astro astro;                    // Sunrise, sunset, moon phases
        
        private List<Hour> hour;                // Hourly forecast (24 hours)
    }

    /**
     * Nested class for daily weather summary
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Day implements Serializable {
        private static final long serialVersionUID = 1L;

        @JsonProperty("maxtemp_c")
        private Double maxtempC;                // Max temperature in Celsius
        
        @JsonProperty("maxtemp_f")
        private Double maxtempF;                // Max temperature in Fahrenheit
        
        @JsonProperty("mintemp_c")
        private Double mintempC;                // Min temperature in Celsius
        
        @JsonProperty("mintemp_f")
        private Double mintempF;                // Min temperature in Fahrenheit
        
        @JsonProperty("avgtemp_c")
        private Double avgtempC;                // Average temperature in Celsius
        
        @JsonProperty("avgtemp_f")
        private Double avgtempF;                // Average temperature in Fahrenheit
        
        @JsonProperty("maxwind_mph")
        private Double maxwindMph;              // Max wind speed in mph
        
        @JsonProperty("maxwind_kph")
        private Double maxwindKph;              // Max wind speed in kph
        
        @JsonProperty("totalprecip_mm")
        private Double totalprecipMm;           // Total precipitation in mm
        
        @JsonProperty("totalprecip_in")
        private Double totalprecipIn;           // Total precipitation in inches
        
        @JsonProperty("totalsnow_cm")
        private Double totalsnowCm;             // Total snow in cm
        
        @JsonProperty("avgvis_km")
        private Double avgvisKm;                // Average visibility in km
        
        @JsonProperty("avgvis_miles")
        private Double avgvisMiles;             // Average visibility in miles
        
        @JsonProperty("avghumidity")
        private Double avghumidity;             // Average humidity percentage
        
        @JsonProperty("daily_will_it_rain")
        private Integer dailyWillItRain;        // 1 = rain expected, 0 = no rain
        
        @JsonProperty("daily_chance_of_rain")
        private Integer dailyChanceOfRain;      // Chance of rain percentage
        
        @JsonProperty("daily_will_it_snow")
        private Integer dailyWillItSnow;        // 1 = snow expected, 0 = no snow
        
        @JsonProperty("daily_chance_of_snow")
        private Integer dailyChanceOfSnow;      // Chance of snow percentage
        
        private WeatherResponse.Condition condition;  // Weather condition
        
        private Double uv;                      // UV index
    }

    /**
     * Nested class for astronomical data
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Astro implements Serializable {
        private static final long serialVersionUID = 1L;

        private String sunrise;                 // Sunrise time
        private String sunset;                  // Sunset time
        private String moonrise;                // Moonrise time
        private String moonset;                 // Moonset time
        
        @JsonProperty("moon_phase")
        private String moonPhase;               // Moon phase
        
        @JsonProperty("moon_illumination")
        private String moonIllumination;        // Moon illumination percentage
        
        @JsonProperty("is_moon_up")
        private Integer isMoonUp;               // 1 = moon is up, 0 = moon is down
        
        @JsonProperty("is_sun_up")
        private Integer isSunUp;                // 1 = sun is up, 0 = sun is down
    }

    /**
     * Nested class for hourly forecast
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Hour implements Serializable {
        private static final long serialVersionUID = 1L;

        @JsonProperty("time_epoch")
        private Long timeEpoch;                 // Time as epoch
        
        private String time;                    // Time (YYYY-MM-DD HH:mm)
        
        @JsonProperty("temp_c")
        private Double tempC;                   // Temperature in Celsius
        
        @JsonProperty("temp_f")
        private Double tempF;                   // Temperature in Fahrenheit
        
        @JsonProperty("is_day")
        private Integer isDay;                  // 1 = day, 0 = night
        
        private WeatherResponse.Condition condition;
        
        @JsonProperty("wind_mph")
        private Double windMph;
        
        @JsonProperty("wind_kph")
        private Double windKph;
        
        @JsonProperty("wind_degree")
        private Integer windDegree;
        
        @JsonProperty("wind_dir")
        private String windDir;
        
        @JsonProperty("pressure_mb")
        private Double pressureMb;
        
        @JsonProperty("pressure_in")
        private Double pressureIn;
        
        @JsonProperty("precip_mm")
        private Double precipMm;
        
        @JsonProperty("precip_in")
        private Double precipIn;
        
        private Integer humidity;
        
        private Integer cloud;
        
        @JsonProperty("feelslike_c")
        private Double feelslikeC;
        
        @JsonProperty("feelslike_f")
        private Double feelslikeF;
        
        @JsonProperty("windchill_c")
        private Double windchillC;
        
        @JsonProperty("windchill_f")
        private Double windchillF;
        
        @JsonProperty("heatindex_c")
        private Double heatindexC;
        
        @JsonProperty("heatindex_f")
        private Double heatindexF;
        
        @JsonProperty("dewpoint_c")
        private Double dewpointC;
        
        @JsonProperty("dewpoint_f")
        private Double dewpointF;
        
        @JsonProperty("will_it_rain")
        private Integer willItRain;
        
        @JsonProperty("chance_of_rain")
        private Integer chanceOfRain;
        
        @JsonProperty("will_it_snow")
        private Integer willItSnow;
        
        @JsonProperty("chance_of_snow")
        private Integer chanceOfSnow;
        
        @JsonProperty("vis_km")
        private Double visKm;
        
        @JsonProperty("vis_miles")
        private Double visMiles;
        
        @JsonProperty("gust_mph")
        private Double gustMph;
        
        @JsonProperty("gust_kph")
        private Double gustKph;
        
        private Double uv;
    }

    /**
     * Nested class for weather alerts
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Alerts implements Serializable {
        private static final long serialVersionUID = 1L;

        private List<Alert> alert;              // List of active alerts
    }

    /**
     * Nested class for individual alert
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Alert implements Serializable {
        private static final long serialVersionUID = 1L;

        private String headline;                // Alert headline
        private String msgtype;                 // Message type
        private String severity;                // Severity level
        private String urgency;                 // Urgency level
        private String areas;                   // Affected areas
        private String category;                // Alert category
        private String certainty;               // Certainty level
        private String event;                   // Event name
        private String note;                    // Additional notes
        private String effective;               // Effective date/time
        private String expires;                 // Expiry date/time
        private String desc;                    // Description
        private String instruction;             // Instructions for public
    }
}
