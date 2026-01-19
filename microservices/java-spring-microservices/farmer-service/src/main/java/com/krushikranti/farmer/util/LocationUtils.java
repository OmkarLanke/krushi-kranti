package com.krushikranti.farmer.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Utility class for GPS location calculations.
 * Implements the Haversine formula for calculating distances between two GPS coordinates.
 */
public class LocationUtils {

    /**
     * Earth's radius in meters (mean radius)
     */
    private static final double EARTH_RADIUS_METERS = 6371000.0;

    /**
     * Calculate the distance between two GPS coordinates using the Haversine formula.
     * 
     * @param lat1 Latitude of first point (in decimal degrees)
     * @param lon1 Longitude of first point (in decimal degrees)
     * @param lat2 Latitude of second point (in decimal degrees)
     * @param lon2 Longitude of second point (in decimal degrees)
     * @return Distance in meters between the two points
     * @throws IllegalArgumentException if any coordinate is null or out of valid range
     */
    public static double calculateDistance(
            BigDecimal lat1, BigDecimal lon1,
            BigDecimal lat2, BigDecimal lon2) {
        
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
            throw new IllegalArgumentException("All coordinates must be non-null");
        }

        double lat1Rad = Math.toRadians(lat1.doubleValue());
        double lon1Rad = Math.toRadians(lon1.doubleValue());
        double lat2Rad = Math.toRadians(lat2.doubleValue());
        double lon2Rad = Math.toRadians(lon2.doubleValue());

        double deltaLat = lat2Rad - lat1Rad;
        double deltaLon = lon2Rad - lon1Rad;

        // Haversine formula
        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(lat1Rad) * Math.cos(lat2Rad)
                * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS_METERS * c;
    }

    /**
     * Calculate the distance between two GPS coordinates using the Haversine formula.
     * Overloaded method that accepts double values.
     * 
     * @param lat1 Latitude of first point (in decimal degrees)
     * @param lon1 Longitude of first point (in decimal degrees)
     * @param lat2 Latitude of second point (in decimal degrees)
     * @param lon2 Longitude of second point (in decimal degrees)
     * @return Distance in meters between the two points
     */
    public static double calculateDistance(
            double lat1, double lon1,
            double lat2, double lon2) {
        
        return calculateDistance(
                BigDecimal.valueOf(lat1),
                BigDecimal.valueOf(lon1),
                BigDecimal.valueOf(lat2),
                BigDecimal.valueOf(lon2)
        );
    }

    /**
     * Check if two GPS coordinates are within a specified distance threshold.
     * 
     * @param lat1 Latitude of first point (in decimal degrees)
     * @param lon1 Longitude of first point (in decimal degrees)
     * @param lat2 Latitude of second point (in decimal degrees)
     * @param lon2 Longitude of second point (in decimal degrees)
     * @param thresholdMeters Distance threshold in meters
     * @return true if the distance between the two points is less than or equal to the threshold
     */
    public static boolean isWithinDistance(
            BigDecimal lat1, BigDecimal lon1,
            BigDecimal lat2, BigDecimal lon2,
            double thresholdMeters) {
        
        double distance = calculateDistance(lat1, lon1, lat2, lon2);
        return distance <= thresholdMeters;
    }

    /**
     * Check if two GPS coordinates are within a specified distance threshold.
     * Overloaded method that accepts double values.
     * 
     * @param lat1 Latitude of first point (in decimal degrees)
     * @param lon1 Longitude of first point (in decimal degrees)
     * @param lat2 Latitude of second point (in decimal degrees)
     * @param lon2 Longitude of second point (in decimal degrees)
     * @param thresholdMeters Distance threshold in meters
     * @return true if the distance between the two points is less than or equal to the threshold
     */
    public static boolean isWithinDistance(
            double lat1, double lon1,
            double lat2, double lon2,
            double thresholdMeters) {
        
        return isWithinDistance(
                BigDecimal.valueOf(lat1),
                BigDecimal.valueOf(lon1),
                BigDecimal.valueOf(lat2),
                BigDecimal.valueOf(lon2),
                thresholdMeters
        );
    }

    /**
     * Validate GPS coordinates.
     * 
     * @param latitude Latitude to validate (must be between -90 and 90)
     * @param longitude Longitude to validate (must be between -180 and 180)
     * @return true if coordinates are valid
     */
    public static boolean isValidCoordinates(BigDecimal latitude, BigDecimal longitude) {
        if (latitude == null || longitude == null) {
            return false;
        }
        
        double lat = latitude.doubleValue();
        double lon = longitude.doubleValue();
        
        return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0;
    }

    /**
     * Validate GPS coordinates.
     * Overloaded method that accepts double values.
     * 
     * @param latitude Latitude to validate (must be between -90 and 90)
     * @param longitude Longitude to validate (must be between -180 and 180)
     * @return true if coordinates are valid
     */
    public static boolean isValidCoordinates(double latitude, double longitude) {
        return isValidCoordinates(BigDecimal.valueOf(latitude), BigDecimal.valueOf(longitude));
    }

    /**
     * Format distance in meters to a human-readable string.
     * 
     * @param distanceMeters Distance in meters
     * @return Formatted string (e.g., "150.5 m" or "1.2 km")
     */
    public static String formatDistance(double distanceMeters) {
        if (distanceMeters < 1000) {
            return String.format("%.1f m", distanceMeters);
        } else {
            double kilometers = distanceMeters / 1000.0;
            return String.format("%.2f km", kilometers);
        }
    }

    /**
     * Calculate distance with rounding to specified decimal places.
     * 
     * @param lat1 Latitude of first point
     * @param lon1 Longitude of first point
     * @param lat2 Latitude of second point
     * @param lon2 Longitude of second point
     * @param decimalPlaces Number of decimal places to round to
     * @return Distance in meters, rounded to specified decimal places
     */
    public static BigDecimal calculateDistanceRounded(
            BigDecimal lat1, BigDecimal lon1,
            BigDecimal lat2, BigDecimal lon2,
            int decimalPlaces) {
        
        double distance = calculateDistance(lat1, lon1, lat2, lon2);
        return BigDecimal.valueOf(distance)
                .setScale(decimalPlaces, RoundingMode.HALF_UP);
    }
}

