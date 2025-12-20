package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.repository.PincodeMasterRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service for pincode-based address lookup.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PincodeService {

    private final PincodeMasterRepository pincodeMasterRepository;

    /**
     * Get address details (district, taluka, state, villages) by pincode.
     * 
     * @param pincode The pincode to lookup
     * @return AddressLookupResponse with address details
     * @throws IllegalArgumentException if pincode not found
     */
    public AddressLookupResponse getAddressByPincode(String pincode) {
        return getAddressByPincode(pincode, "en");
    }

    /**
     * Get address details (district, taluka, state, villages) by pincode with language support.
     * 
     * @param pincode The pincode to lookup
     * @param language Language code: "en", "hi", or "mr" (defaults to "en" if invalid)
     * @return AddressLookupResponse with address details in the requested language
     * @throws IllegalArgumentException if pincode not found
     */
    public AddressLookupResponse getAddressByPincode(String pincode, String language) {
        if (pincode == null || pincode.trim().isEmpty()) {
            throw new IllegalArgumentException("Pincode cannot be empty");
        }

        // Normalize language code
        if (language == null || language.trim().isEmpty()) {
            language = "en";
        }
        language = language.toLowerCase().trim();
        if (!language.equals("hi") && !language.equals("mr")) {
            language = "en"; // Default to English
        }

        // Get distinct district, taluka, state, villages based on language
        List<String> districts;
        List<String> talukas;
        List<String> states;
        List<String> villages;

        if ("hi".equals(language)) {
            districts = pincodeMasterRepository.findDistrictsByPincodeHi(pincode);
            talukas = pincodeMasterRepository.findTalukasByPincodeHi(pincode);
            states = pincodeMasterRepository.findStatesByPincodeHi(pincode);
            villages = pincodeMasterRepository.findVillagesByPincodeHi(pincode);
        } else if ("mr".equals(language)) {
            districts = pincodeMasterRepository.findDistrictsByPincodeMr(pincode);
            talukas = pincodeMasterRepository.findTalukasByPincodeMr(pincode);
            states = pincodeMasterRepository.findStatesByPincodeMr(pincode);
            villages = pincodeMasterRepository.findVillagesByPincodeMr(pincode);
        } else {
            // English (default)
            districts = pincodeMasterRepository.findDistrictsByPincode(pincode);
            talukas = pincodeMasterRepository.findTalukasByPincode(pincode);
            states = pincodeMasterRepository.findStatesByPincode(pincode);
            villages = pincodeMasterRepository.findVillagesByPincode(pincode);
        }

        if (districts.isEmpty() || talukas.isEmpty() || states.isEmpty()) {
            log.warn("Pincode not found: {}", pincode);
            throw new IllegalArgumentException("Pincode not found: " + pincode);
        }

        // Take the first value if multiple exist (should typically be the same)
        String district = districts.get(0);
        String taluka = talukas.get(0);
        String state = states.get(0);
        
        // Log warning if multiple values exist (data inconsistency)
        if (districts.size() > 1) {
            log.warn("Pincode {} has multiple districts: {}. Using first: {}", pincode, districts, district);
        }
        if (talukas.size() > 1) {
            log.warn("Pincode {} has multiple talukas: {}. Using first: {}", pincode, talukas, taluka);
        }
        if (states.size() > 1) {
            log.warn("Pincode {} has multiple states: {}. Using first: {}", pincode, states, state);
        }

        log.debug("Found address for pincode {} (language: {}): {} villages", pincode, language, villages.size());
        
        return AddressLookupResponse.builder()
                .pincode(pincode)
                .district(district)
                .taluka(taluka)
                .state(state)
                .villages(villages)
                .build();
    }

    /**
     * Check if pincode exists in the database.
     * 
     * @param pincode The pincode to check
     * @return true if pincode exists, false otherwise
     */
    public boolean pincodeExists(String pincode) {
        return !pincodeMasterRepository.findDistrictsByPincode(pincode).isEmpty();
    }
}

