package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Service for pincode-based address lookup via data.gov.in India Post API.
 * Language parameter is accepted for API compatibility but the external API
 * returns English-only data; hi/mr requests fall back to English.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PincodeService {

    private final DataGovPincodeClient dataGovPincodeClient;

    public AddressLookupResponse getAddressByPincode(String pincode) {
        return getAddressByPincode(pincode, "en");
    }

    public AddressLookupResponse getAddressByPincode(String pincode, String language) {
        if (pincode == null || pincode.trim().isEmpty()) {
            throw new IllegalArgumentException("Pincode cannot be empty");
        }

        if (language != null && !language.equals("en")) {
            log.debug("Language '{}' requested but data.gov.in returns English only; returning English for pincode {}", language, pincode);
        }

        return dataGovPincodeClient.lookup(pincode.trim());
    }

    public boolean pincodeExists(String pincode) {
        try {
            dataGovPincodeClient.lookup(pincode);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
