package com.krushikranti.farmer.controller;

import com.krushikranti.auth.grpc.UserInfoResponse;
import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmerRepository;
import com.krushikranti.farmer.service.AuthServiceClient;
import com.krushikranti.farmer.service.PincodeService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("FarmerController Integration Tests")
class FarmerControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private FarmerRepository farmerRepository;

    @MockBean
    private AuthServiceClient authServiceClient;

    @MockBean
    private PincodeService pincodeService;

    private Long userId;
    private UserInfoResponse userInfoResponse;

    @BeforeEach
    void setUp() {
        farmerRepository.deleteAll();
        userId = 1L;

        userInfoResponse = UserInfoResponse.newBuilder()
                .setUserId(String.valueOf(userId))
                .setEmail("farmer@example.com")
                .setPhoneNumber("9876543210")
                .setUsername("farmer1")
                .addAllRoles(List.of("FARMER"))
                .setActive(true)
                .build();

        when(authServiceClient.getUserById(String.valueOf(userId))).thenReturn(userInfoResponse);
    }

    @Test
    @DisplayName("GET /farmer/profile/my-details - profile exists")
    void getMyDetails_ProfileExists_Returns200() throws Exception {
        // Given
        Farmer farmer = Farmer.builder()
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
        farmerRepository.save(farmer);

        // When/Then
        mockMvc.perform(get("/farmer/profile/my-details")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Farmer profile retrieved successfully"))
                .andExpect(jsonPath("$.data.userId").value(userId))
                .andExpect(jsonPath("$.data.firstName").value("John"))
                .andExpect(jsonPath("$.data.lastName").value("Doe"))
                .andExpect(jsonPath("$.data.email").value("farmer@example.com"))
                .andExpect(jsonPath("$.data.phoneNumber").value("9876543210"));
    }

    @Test
    @DisplayName("GET /farmer/profile/my-details - profile does not exist")
    void getMyDetails_ProfileNotExists_Returns200WithAuthData() throws Exception {
        // When/Then
        mockMvc.perform(get("/farmer/profile/my-details")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Farmer profile retrieved successfully"))
                .andExpect(jsonPath("$.data.userId").value(userId))
                .andExpect(jsonPath("$.data.email").value("farmer@example.com"))
                .andExpect(jsonPath("$.data.phoneNumber").value("9876543210"));
    }

    @Test
    @DisplayName("PUT /farmer/profile/my-details - create new profile")
    void saveMyDetails_CreateNew_Returns200() throws Exception {
        // Given
        AddressLookupResponse addressLookup = AddressLookupResponse.builder()
                .pincode("411001")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .villages(List.of("Village1", "Village2"))
                .build();

        when(pincodeService.getAddressByPincode("411001")).thenReturn(addressLookup);

        String requestBody = """
                {
                    "firstName": "John",
                    "lastName": "Doe",
                    "dateOfBirth": "1990-01-01",
                    "gender": "MALE",
                    "alternatePhone": "9876543211",
                    "pincode": "411001",
                    "village": "Village1"
                }
                """;

        // When/Then
        mockMvc.perform(put("/farmer/profile/my-details")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Farmer profile saved successfully"))
                .andExpect(jsonPath("$.data.firstName").value("John"))
                .andExpect(jsonPath("$.data.lastName").value("Doe"))
                .andExpect(jsonPath("$.data.pincode").value("411001"))
                .andExpect(jsonPath("$.data.district").value("Pune"));
    }

    @Test
    @DisplayName("PUT /farmer/profile/my-details - validation error")
    void saveMyDetails_ValidationError_Returns400() throws Exception {
        // Given
        String invalidRequestBody = """
                {
                    "firstName": "",
                    "lastName": "Doe",
                    "dateOfBirth": "1990-01-01",
                    "gender": "MALE",
                    "pincode": "411001",
                    "village": "Village1"
                }
                """;

        // When/Then
        mockMvc.perform(put("/farmer/profile/my-details")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidRequestBody))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Validation failed")));
    }

    @Test
    @DisplayName("GET /farmer/profile/address/lookup - success")
    void lookupAddress_Success_Returns200() throws Exception {
        // Given
        AddressLookupResponse addressLookup = AddressLookupResponse.builder()
                .pincode("411001")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .villages(List.of("Village1", "Village2", "Village3"))
                .build();

        when(pincodeService.getAddressByPincode("411001")).thenReturn(addressLookup);

        // When/Then
        mockMvc.perform(get("/farmer/profile/address/lookup")
                        .param("pincode", "411001")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Address lookup successful"))
                .andExpect(jsonPath("$.data.pincode").value("411001"))
                .andExpect(jsonPath("$.data.district").value("Pune"))
                .andExpect(jsonPath("$.data.taluka").value("Pune"))
                .andExpect(jsonPath("$.data.state").value("Maharashtra"))
                .andExpect(jsonPath("$.data.villages").isArray())
                .andExpect(jsonPath("$.data.villages.length()").value(3));
    }

    @Test
    @DisplayName("GET /farmer/profile/address/lookup - pincode not found")
    void lookupAddress_PincodeNotFound_Returns400() throws Exception {
        // Given
        when(pincodeService.getAddressByPincode("999999"))
                .thenThrow(new IllegalArgumentException("Pincode not found: 999999"));

        // When/Then
        mockMvc.perform(get("/farmer/profile/address/lookup")
                        .param("pincode", "999999")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Pincode not found: 999999"));
    }
}

