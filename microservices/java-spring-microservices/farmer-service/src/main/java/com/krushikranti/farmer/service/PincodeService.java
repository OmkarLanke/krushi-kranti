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
        if (pincode == null || pincode.trim().isEmpty()) {
            throw new IllegalArgumentException("Pincode cannot be empty");
        }

        // Get distinct district, taluka, state (may have multiple, take first)
        List<String> districts = pincodeMasterRepository.findDistrictsByPincode(pincode);
        List<String> talukas = pincodeMasterRepository.findTalukasByPincode(pincode);
        List<String> states = pincodeMasterRepository.findStatesByPincode(pincode);
        List<String> villages = pincodeMasterRepository.findVillagesByPincode(pincode);

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

        log.debug("Found address for pincode {}: {} villages", pincode, villages.size());
        
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

