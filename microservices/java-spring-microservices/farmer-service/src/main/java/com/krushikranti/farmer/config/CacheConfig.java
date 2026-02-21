package com.krushikranti.farmer.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for Spring Cache with Caffeine.
 * 
 * Caching is used to reduce external API calls to WeatherAPI.com.
 * 
 * Cache Configuration (from application.yml):
 * - Cache Type: Caffeine (in-memory)
 * - Max Size: 500 entries per cache
 * - TTL: 30 minutes (expireAfterWrite)
 * - Caches: currentWeather, weatherForecast
 * 
 * Why Caffeine?
 * - High performance, thread-safe in-memory cache
 * - Automatic eviction based on size and time
 * - Better than ConcurrentHashMap for caching scenarios
 * - Lightweight (no Redis needed for small-scale caching)
 * 
 * Cache Keys:
 * - currentWeather: "latitude_longitude"
 * - weatherForecast: "latitude_longitude_days"
 * 
 * Example:
 * - Key "18.52_73.85" stores current weather for Pune
 * - Key "18.52_73.85_7" stores 7-day forecast for Pune
 * 
 * Note: If your application scales horizontally (multiple instances),
 * consider replacing Caffeine with Redis for distributed caching.
 * 
 * @author KrushiKranti Team
 */
@Configuration
@EnableCaching
public class CacheConfig {
    
    /**
     * No additional beans needed.
     * Spring Boot auto-configures Caffeine based on application.yml settings.
     * 
     * The following properties from application.yml are used:
     * - spring.cache.type=caffeine
     * - spring.cache.cache-names=currentWeather,weatherForecast
     * - spring.cache.caffeine.spec=maximumSize=500,expireAfterWrite=30m
     */
}
