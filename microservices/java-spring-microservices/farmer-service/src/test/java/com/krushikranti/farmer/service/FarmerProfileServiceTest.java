package com.krushikranti.farmer.service;

import com.krushikranti.auth.grpc.UserInfoResponse;
import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.dto.MyDetailsRequest;
import com.krushikranti.farmer.dto.MyDetailsResponse;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("FarmerProfileService Unit Tests")
class FarmerProfileServiceTest {

    @Mock
    private FarmerRepository farmerRepository;

    @Mock
    private AuthServiceClient authServiceClient;

    @Mock
    private PincodeService pincodeService;

    @InjectMocks
    private FarmerProfileService farmerProfileService;

    private Long userId;
    private UserInfoResponse userInfoResponse;
    private AddressLookupResponse addressLookupResponse;
    private MyDetailsRequest myDetailsRequest;

    @BeforeEach
    void setUp() {
        userId = 1L;

        userInfoResponse = UserInfoResponse.newBuilder()
                .setUserId(String.valueOf(userId))
                .setEmail("farmer@example.com")
                .setPhoneNumber("9876543210")
                .setUsername("farmer1")
                .addAllRoles(List.of("FARMER"))
                .setActive(true)
                .build();

        addressLookupResponse = AddressLookupResponse.builder()
                .pincode("411001")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .villages(List.of("Village1", "Village2", "Village3"))
                .build();

        myDetailsRequest = MyDetailsRequest.builder()
                .firstName("John")
                .lastName("Doe")
                .dateOfBirth(LocalDate.of(1990, 1, 1))
                .gender(Farmer.Gender.MALE)
                .alternatePhone("9876543211")
                .pincode("411001")
                .village("Village1")
                .build();
    }

    @Test
    @DisplayName("Get my details - profile exists")
    void getMyDetails_ProfileExists_ReturnsCompleteResponse() {
        // Given
        Farmer farmer = Farmer.builder()
                .id(1L)
                .userId(userId)
                .firstName("John")
                .lastName("Doe")
                .dateOfBirth(LocalDate.of(1990, 1, 1))
                .gender(Farmer.Gender.MALE)
                .alternatePhone("9876543211")
                .pincode("411001")
                .village("Village1")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .build();

        when(farmerRepository.findByUserId(userId)).thenReturn(Optional.of(farmer));
        when(authServiceClient.getUserById(String.valueOf(userId))).thenReturn(userInfoResponse);

        // When
        MyDetailsResponse response = farmerProfileService.getMyDetails(userId);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getUserId()).isEqualTo(userId);
        assertThat(response.getFirstName()).isEqualTo("John");
        assertThat(response.getLastName()).isEqualTo("Doe");
        assertThat(response.getEmail()).isEqualTo("farmer@example.com");
        assertThat(response.getPhoneNumber()).isEqualTo("9876543210");
        assertThat(response.getAlternatePhone()).isEqualTo("9876543211");
        assertThat(response.getPincode()).isEqualTo("411001");

        verify(farmerRepository).findByUserId(userId);
        verify(authServiceClient).getUserById(String.valueOf(userId));
    }

    @Test
    @DisplayName("Get my details - profile does not exist")
    void getMyDetails_ProfileNotExists_ReturnsAuthDataOnly() {
        // Given
        when(farmerRepository.findByUserId(userId)).thenReturn(Optional.empty());
        when(authServiceClient.getUserById(String.valueOf(userId))).thenReturn(userInfoResponse);

        // When
        MyDetailsResponse response = farmerProfileService.getMyDetails(userId);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getUserId()).isEqualTo(userId);
        assertThat(response.getEmail()).isEqualTo("farmer@example.com");
        assertThat(response.getPhoneNumber()).isEqualTo("9876543210");
        assertThat(response.getFirstName()).isNull();
        assertThat(response.getId()).isNull();

        verify(farmerRepository).findByUserId(userId);
        verify(authServiceClient).getUserById(String.valueOf(userId));
    }

    @Test
    @DisplayName("Save my details - create new profile")
    void saveMyDetails_CreateNew_ReturnsSavedResponse() {
        // Given
        when(farmerRepository.findByUserId(userId)).thenReturn(Optional.empty());
        when(pincodeService.getAddressByPincode("411001")).thenReturn(addressLookupResponse);
        when(authServiceClient.getUserById(String.valueOf(userId))).thenReturn(userInfoResponse);

        Farmer savedFarmer = Farmer.builder()
                .id(1L)
                .userId(userId)
                .firstName("John")
                .lastName("Doe")
                .dateOfBirth(LocalDate.of(1990, 1, 1))
                .gender(Farmer.Gender.MALE)
                .alternatePhone("9876543211")
                .pincode("411001")
                .village("Village1")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .build();

        when(farmerRepository.save(any(Farmer.class))).thenReturn(savedFarmer);

        // When
        MyDetailsResponse response = farmerProfileService.saveMyDetails(userId, myDetailsRequest);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getFirstName()).isEqualTo("John");
        assertThat(response.getLastName()).isEqualTo("Doe");
        assertThat(response.getEmail()).isEqualTo("farmer@example.com");
        assertThat(response.getPhoneNumber()).isEqualTo("9876543210");
        assertThat(response.getPincode()).isEqualTo("411001");
        assertThat(response.getDistrict()).isEqualTo("Pune");
        assertThat(response.getTaluka()).isEqualTo("Pune");
        assertThat(response.getState()).isEqualTo("Maharashtra");

        verify(farmerRepository).findByUserId(userId);
        verify(pincodeService).getAddressByPincode("411001");
        verify(authServiceClient).getUserById(String.valueOf(userId));
        verify(farmerRepository).save(any(Farmer.class));
    }

    @Test
    @DisplayName("Save my details - update existing profile")
    void saveMyDetails_UpdateExisting_ReturnsUpdatedResponse() {
        // Given
        Farmer existingFarmer = Farmer.builder()
                .id(1L)
                .userId(userId)
                .firstName("Jane")
                .lastName("Smith")
                .dateOfBirth(LocalDate.of(1985, 5, 15))
                .gender(Farmer.Gender.FEMALE)
                .build();

        when(farmerRepository.findByUserId(userId)).thenReturn(Optional.of(existingFarmer));
        when(pincodeService.getAddressByPincode("411001")).thenReturn(addressLookupResponse);
        when(authServiceClient.getUserById(String.valueOf(userId))).thenReturn(userInfoResponse);
        when(farmerRepository.save(any(Farmer.class))).thenReturn(existingFarmer);

        // When
        MyDetailsResponse response = farmerProfileService.saveMyDetails(userId, myDetailsRequest);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getFirstName()).isEqualTo("John");
        assertThat(response.getLastName()).isEqualTo("Doe");
        assertThat(response.getPincode()).isEqualTo("411001");

        verify(farmerRepository).findByUserId(userId);
        verify(pincodeService).getAddressByPincode("411001");
        verify(authServiceClient).getUserById(String.valueOf(userId));
        verify(farmerRepository).save(existingFarmer);
    }

    @Test
    @DisplayName("Save my details - invalid village for pincode")
    void saveMyDetails_InvalidVillage_ThrowsException() {
        // Given
        MyDetailsRequest requestWithInvalidVillage = MyDetailsRequest.builder()
                .firstName("John")
                .lastName("Doe")
                .dateOfBirth(LocalDate.of(1990, 1, 1))
                .gender(Farmer.Gender.MALE)
                .pincode("411001")
                .village("InvalidVillage")
                .build();

        when(pincodeService.getAddressByPincode("411001")).thenReturn(addressLookupResponse);

        // When/Then
        assertThatThrownBy(() -> farmerProfileService.saveMyDetails(userId, requestWithInvalidVillage))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Selected village does not exist for the given pincode");

        verify(pincodeService).getAddressByPincode("411001");
        verify(farmerRepository, never()).save(any());
    }
}

