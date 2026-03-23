package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * HTTP client for India Post pincode lookup via data.gov.in OGD API.
 *
 * API returns records like:
 * <pre>
 * {
 *   "officename": "Gargundi B.O",
 *   "pincode": "414303",
 *   "taluk": "Parner",
 *   "districtname": "Ahmed Nagar",
 *   "statename": "MAHARASHTRA",
 *   ...
 * }
 * </pre>
 *
 * Multiple records per pincode → officename list becomes the village dropdown.
 */
@Component
@Slf4j
public class DataGovPincodeClient {

    private static final Pattern OFFICE_SUFFIX = Pattern.compile(
            "\\s+(B\\.O|S\\.O|H\\.O|B\\.O\\.|S\\.O\\.|H\\.O\\.)\\s*$", Pattern.CASE_INSENSITIVE);

    private final WebClient webClient;
    private final String apiKey;
    private final String resourceId;
    private final int maxResults;

    public DataGovPincodeClient(
            @Qualifier("dataGovWebClient") WebClient webClient,
            @Value("${datagovin.api.key:}") String apiKey,
            @Value("${datagovin.api.resource-id:6176ee09-3d56-4a3b-8115-21841576b2f6}") String resourceId,
            @Value("${datagovin.api.max-results:100}") int maxResults) {
        this.webClient = webClient;
        this.apiKey = apiKey;
        this.resourceId = resourceId;
        this.maxResults = maxResults;
    }

    /**
     * Lookup address by pincode via data.gov.in API.
     *
     * @param pincode 6-digit Indian postal code
     * @return AddressLookupResponse with district, taluka, state, villages
     * @throws IllegalArgumentException if pincode not found or API key missing
     * @throws RuntimeException on API communication errors
     */
    public AddressLookupResponse lookup(String pincode) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("DATAGOVIN_API_KEY is not configured");
        }

        log.debug("Calling data.gov.in for pincode: {}", pincode);

        Map<String, Object> body;
        try {
            body = webClient.get()
                    .uri("/{resourceId}?api-key={apiKey}&format=json&limit={limit}&filters[pincode]={pincode}",
                            resourceId, apiKey, maxResults, pincode)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
        } catch (WebClientResponseException e) {
            log.error("data.gov.in API error for pincode {}: {} {}", pincode, e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Pincode lookup API error: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("data.gov.in API call failed for pincode {}: {}", pincode, e.getMessage());
            throw new RuntimeException("Pincode lookup failed: " + e.getMessage(), e);
        }

        if (body == null) {
            throw new RuntimeException("Empty response from pincode API");
        }

        if (body.containsKey("error")) {
            String error = String.valueOf(body.get("error"));
            log.error("data.gov.in API returned error: {}", error);
            throw new RuntimeException("Pincode API error: " + error);
        }

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> records = (List<Map<String, Object>>) body.get("records");

        if (records == null || records.isEmpty()) {
            throw new IllegalArgumentException("Pincode not found: " + pincode);
        }

        return mapToResponse(pincode, records);
    }

    private AddressLookupResponse mapToResponse(String pincode, List<Map<String, Object>> records) {
        String district = null;
        String taluka = null;
        String state = null;
        Set<String> villageSet = new LinkedHashSet<>();

        for (Map<String, Object> record : records) {
            String officeName = strVal(record, "officename");
            if (officeName != null) {
                villageSet.add(cleanOfficeName(officeName));
            }

            if (district == null) {
                district = titleCase(strVal(record, "districtname"));
            }
            if (taluka == null) {
                taluka = titleCase(strVal(record, "taluk"));
            }
            if (state == null) {
                state = titleCase(strVal(record, "statename"));
            }
        }

        if (district == null || state == null) {
            throw new IllegalArgumentException("Pincode not found: " + pincode);
        }

        List<String> villages = villageSet.stream().sorted().collect(Collectors.toList());

        log.debug("Pincode {} resolved: district={}, taluka={}, state={}, {} villages",
                pincode, district, taluka, state, villages.size());

        return AddressLookupResponse.builder()
                .pincode(pincode)
                .district(district)
                .taluka(taluka != null ? taluka : "")
                .state(state)
                .villages(villages)
                .build();
    }

    /**
     * Strip postal suffix (B.O, S.O, H.O) from office name to get a cleaner village name.
     */
    private String cleanOfficeName(String officeName) {
        String cleaned = OFFICE_SUFFIX.matcher(officeName.trim()).replaceAll("");
        return titleCase(cleaned);
    }

    private String strVal(Map<String, Object> map, String key) {
        Object v = map.get(key);
        if (v == null) return null;
        String s = v.toString().trim();
        return s.isEmpty() ? null : s;
    }

    /**
     * Convert "AHMED NAGAR" → "Ahmed Nagar", "MAHARASHTRA" → "Maharashtra".
     */
    private String titleCase(String input) {
        if (input == null || input.isEmpty()) return input;
        String[] words = input.toLowerCase().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String word : words) {
            if (!sb.isEmpty()) sb.append(' ');
            if (!word.isEmpty()) {
                sb.append(Character.toUpperCase(word.charAt(0)));
                if (word.length() > 1) sb.append(word.substring(1));
            }
        }
        return sb.toString();
    }
}
