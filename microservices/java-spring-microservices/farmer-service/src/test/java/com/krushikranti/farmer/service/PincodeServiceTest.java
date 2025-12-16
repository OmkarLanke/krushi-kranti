package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.repository.PincodeMasterRepository;
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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("PincodeService Unit Tests")
class PincodeServiceTest {

    @Mock
    private PincodeMasterRepository pincodeMasterRepository;

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
        // Given
        String district = "Pune";
        String taluka = "Pune";
        String state = "Maharashtra";
        List<String> villages = List.of("Village1", "Village2", "Village3");

        when(pincodeMasterRepository.findDistrictsByPincode(validPincode))
                .thenReturn(List.of(district));
        when(pincodeMasterRepository.findTalukasByPincode(validPincode))
                .thenReturn(List.of(taluka));
        when(pincodeMasterRepository.findStatesByPincode(validPincode))
                .thenReturn(List.of(state));
        when(pincodeMasterRepository.findVillagesByPincode(validPincode))
                .thenReturn(villages);

        // When
        AddressLookupResponse response = pincodeService.getAddressByPincode(validPincode);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getPincode()).isEqualTo(validPincode);
        assertThat(response.getDistrict()).isEqualTo(district);
        assertThat(response.getTaluka()).isEqualTo(taluka);
        assertThat(response.getState()).isEqualTo(state);
        assertThat(response.getVillages()).hasSize(3);
        assertThat(response.getVillages()).containsExactlyInAnyOrder("Village1", "Village2", "Village3");

        verify(pincodeMasterRepository).findDistrictsByPincode(validPincode);
        verify(pincodeMasterRepository).findTalukasByPincode(validPincode);
        verify(pincodeMasterRepository).findStatesByPincode(validPincode);
        verify(pincodeMasterRepository).findVillagesByPincode(validPincode);
    }

    @Test
    @DisplayName("Get address by pincode - pincode not found")
    void getAddressByPincode_PincodeNotFound_ThrowsException() {
        // Given
        // Service calls all repository methods before checking, so we need to mock all
        when(pincodeMasterRepository.findDistrictsByPincode(invalidPincode))
                .thenReturn(List.of());
        when(pincodeMasterRepository.findTalukasByPincode(invalidPincode))
                .thenReturn(List.of());
        when(pincodeMasterRepository.findStatesByPincode(invalidPincode))
                .thenReturn(List.of());
        when(pincodeMasterRepository.findVillagesByPincode(invalidPincode))
                .thenReturn(List.of());

        // When/Then
        assertThatThrownBy(() -> pincodeService.getAddressByPincode(invalidPincode))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Pincode not found: " + invalidPincode);

        verify(pincodeMasterRepository).findDistrictsByPincode(invalidPincode);
        verify(pincodeMasterRepository).findTalukasByPincode(invalidPincode);
        verify(pincodeMasterRepository).findStatesByPincode(invalidPincode);
        verify(pincodeMasterRepository).findVillagesByPincode(invalidPincode);
    }

    @Test
    @DisplayName("Get address by pincode - empty pincode")
    void getAddressByPincode_EmptyPincode_ThrowsException() {
        // When/Then
        assertThatThrownBy(() -> pincodeService.getAddressByPincode(""))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Pincode cannot be empty");

        assertThatThrownBy(() -> pincodeService.getAddressByPincode(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Pincode cannot be empty");

        verify(pincodeMasterRepository, never()).findDistrictsByPincode(anyString());
    }

    @Test
    @DisplayName("Pincode exists - returns true")
    void pincodeExists_ValidPincode_ReturnsTrue() {
        // Given
        when(pincodeMasterRepository.findDistrictsByPincode(validPincode))
                .thenReturn(List.of("Pune"));

        // When
        boolean exists = pincodeService.pincodeExists(validPincode);

        // Then
        assertThat(exists).isTrue();
        verify(pincodeMasterRepository).findDistrictsByPincode(validPincode);
    }

    @Test
    @DisplayName("Pincode exists - returns false")
    void pincodeExists_InvalidPincode_ReturnsFalse() {
        // Given
        when(pincodeMasterRepository.findDistrictsByPincode(invalidPincode))
                .thenReturn(List.of());

        // When
        boolean exists = pincodeService.pincodeExists(invalidPincode);

        // Then
        assertThat(exists).isFalse();
        verify(pincodeMasterRepository).findDistrictsByPincode(invalidPincode);
    }
}

