package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("PincodeService Unit Tests")
class PincodeServiceTest {

    @Mock
    private DataGovPincodeClient dataGovPincodeClient;

    @InjectMocks
    private PincodeService pincodeService;

    private String validPincode;
    private String invalidPincode;

    @BeforeEach
    void setUp() {
        validPincode = "411001";
        invalidPincode = "999999";
    }

    @Test
    @DisplayName("Get address by pincode - success")
    void getAddressByPincode_Success_ReturnsAddressLookupResponse() {
        AddressLookupResponse expected = AddressLookupResponse.builder()
                .pincode(validPincode)
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .villages(List.of("Village1", "Village2", "Village3"))
                .build();

        when(dataGovPincodeClient.lookup(validPincode)).thenReturn(expected);

        AddressLookupResponse response = pincodeService.getAddressByPincode(validPincode);

        assertThat(response).isNotNull();
        assertThat(response.getPincode()).isEqualTo(validPincode);
        assertThat(response.getDistrict()).isEqualTo("Pune");
        assertThat(response.getTaluka()).isEqualTo("Pune");
        assertThat(response.getState()).isEqualTo("Maharashtra");
        assertThat(response.getVillages()).hasSize(3);
        assertThat(response.getVillages()).containsExactlyInAnyOrder("Village1", "Village2", "Village3");

        verify(dataGovPincodeClient).lookup(validPincode);
    }

    @Test
    @DisplayName("Get address by pincode - pincode not found")
    void getAddressByPincode_PincodeNotFound_ThrowsException() {
        when(dataGovPincodeClient.lookup(invalidPincode))
                .thenThrow(new IllegalArgumentException("Pincode not found: " + invalidPincode));

        assertThatThrownBy(() -> pincodeService.getAddressByPincode(invalidPincode))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Pincode not found: " + invalidPincode);

        verify(dataGovPincodeClient).lookup(invalidPincode);
    }

    @Test
    @DisplayName("Get address by pincode - empty pincode")
    void getAddressByPincode_EmptyPincode_ThrowsException() {
        assertThatThrownBy(() -> pincodeService.getAddressByPincode(""))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Pincode cannot be empty");

        assertThatThrownBy(() -> pincodeService.getAddressByPincode(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Pincode cannot be empty");

        verify(dataGovPincodeClient, never()).lookup(anyString());
    }

    @Test
    @DisplayName("Pincode exists - returns true")
    void pincodeExists_ValidPincode_ReturnsTrue() {
        AddressLookupResponse response = AddressLookupResponse.builder()
                .pincode(validPincode).district("Pune").taluka("Pune")
                .state("Maharashtra").villages(List.of("V1")).build();
        when(dataGovPincodeClient.lookup(validPincode)).thenReturn(response);

        assertThat(pincodeService.pincodeExists(validPincode)).isTrue();
        verify(dataGovPincodeClient).lookup(validPincode);
    }

    @Test
    @DisplayName("Pincode exists - returns false")
    void pincodeExists_InvalidPincode_ReturnsFalse() {
        when(dataGovPincodeClient.lookup(invalidPincode))
                .thenThrow(new IllegalArgumentException("Pincode not found: " + invalidPincode));

        assertThat(pincodeService.pincodeExists(invalidPincode)).isFalse();
        verify(dataGovPincodeClient).lookup(invalidPincode);
    }
}
