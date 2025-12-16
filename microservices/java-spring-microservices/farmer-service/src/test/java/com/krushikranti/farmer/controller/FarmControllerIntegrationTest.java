package com.krushikranti.farmer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.dto.FarmRequest;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmRepository;
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

import java.math.BigDecimal;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("FarmController Integration Tests")
class FarmControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private FarmRepository farmRepository;

    @Autowired
    private FarmerRepository farmerRepository;

    @MockBean
    private AuthServiceClient authServiceClient;

    @MockBean
    private PincodeService pincodeService;

    private Farmer testFarmer;
    private Farm testFarm;
    private final Long TEST_USER_ID = 100L;

    @BeforeEach
    void setUp() {
        farmRepository.deleteAll();
        farmerRepository.deleteAll();

        // Create test farmer
        testFarmer = Farmer.builder()
                .userId(TEST_USER_ID)
                .firstName("John")
                .lastName("Doe")
                .pincode("411001")
                .village("Shivajinagar")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .gender(Farmer.Gender.MALE)
                .build();
        testFarmer = farmerRepository.save(testFarmer);

        // Create test farm
        testFarm = Farm.builder()
                .farmer(testFarmer)
                .farmName("Main Farm")
                .farmType(Farm.FarmType.ORGANIC)
                .totalAreaAcres(new BigDecimal("5.50"))
                .pincode("411001")
                .village("Shivajinagar")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .soilType(Farm.SoilType.BLACK)
                .irrigationType(Farm.IrrigationType.DRIP)
                .landOwnership(Farm.LandOwnership.OWNED)
                .surveyNumber("123/45")
                .estimatedLandValue(new BigDecimal("500000"))
                .encumbranceStatus(Farm.EncumbranceStatus.FREE)
                .isVerified(false)
                .isActive(true)
                .build();

        // Mock pincode service
        AddressLookupResponse addressResponse = AddressLookupResponse.builder()
                .pincode("411001")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .villages(List.of("Shivajinagar", "Deccan", "Kothrud"))
                .build();
        when(pincodeService.getAddressByPincode(anyString())).thenReturn(addressResponse);
    }

    @Test
    @DisplayName("GET /farmer/profile/farms - returns all farms")
    void getAllFarms_ReturnsAllFarms() throws Exception {
        // Given
        farmRepository.save(testFarm);

        // When/Then
        mockMvc.perform(get("/farmer/profile/farms")
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Farms retrieved successfully")))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].farmName", is("Main Farm")));
    }

    @Test
    @DisplayName("GET /farmer/profile/farms - returns empty list when no farms")
    void getAllFarms_NoFarms_ReturnsEmptyList() throws Exception {
        mockMvc.perform(get("/farmer/profile/farms")
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }

    @Test
    @DisplayName("GET /farmer/profile/farms/{farmId} - returns specific farm")
    void getFarmById_ReturnsFarm() throws Exception {
        // Given
        Farm savedFarm = farmRepository.save(testFarm);

        // When/Then
        mockMvc.perform(get("/farmer/profile/farms/" + savedFarm.getId())
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Farm retrieved successfully")))
                .andExpect(jsonPath("$.data.farmName", is("Main Farm")))
                .andExpect(jsonPath("$.data.totalAreaAcres", is(5.50)))
                .andExpect(jsonPath("$.data.landOwnership", is("OWNED")));
    }

    @Test
    @DisplayName("GET /farmer/profile/farms/{farmId} - returns 400 for non-existent farm")
    void getFarmById_NotFound_Returns400() throws Exception {
        mockMvc.perform(get("/farmer/profile/farms/999")
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Farm not found")));
    }

    @Test
    @DisplayName("POST /farmer/profile/farms - creates new farm")
    void createFarm_Success_Returns201() throws Exception {
        // Given
        FarmRequest request = FarmRequest.builder()
                .farmName("New Farm")
                .farmType(Farm.FarmType.ORGANIC)
                .totalAreaAcres(new BigDecimal("10.00"))
                .pincode("411001")
                .village("Shivajinagar")
                .soilType(Farm.SoilType.BLACK)
                .irrigationType(Farm.IrrigationType.DRIP)
                .landOwnership(Farm.LandOwnership.OWNED)
                .surveyNumber("999/88")
                .estimatedLandValue(new BigDecimal("1000000"))
                .build();

        // When/Then
        mockMvc.perform(post("/farmer/profile/farms")
                        .header("X-User-Id", TEST_USER_ID.toString())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message", is("Farm created successfully")))
                .andExpect(jsonPath("$.data.farmName", is("New Farm")))
                .andExpect(jsonPath("$.data.district", is("Pune")))
                .andExpect(jsonPath("$.data.state", is("Maharashtra")));
    }

    @Test
    @DisplayName("POST /farmer/profile/farms - validation error for missing required fields")
    void createFarm_ValidationError_Returns400() throws Exception {
        // Given - missing required fields
        FarmRequest request = FarmRequest.builder()
                .farmName("") // Invalid: blank
                .build();

        // When/Then
        mockMvc.perform(post("/farmer/profile/farms")
                        .header("X-User-Id", TEST_USER_ID.toString())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Validation failed")));
    }

    @Test
    @DisplayName("POST /farmer/profile/farms - duplicate farm name")
    void createFarm_DuplicateName_Returns400() throws Exception {
        // Given
        farmRepository.save(testFarm);
        
        FarmRequest request = FarmRequest.builder()
                .farmName("Main Farm") // Duplicate name
                .farmType(Farm.FarmType.ORGANIC)
                .totalAreaAcres(new BigDecimal("10.00"))
                .pincode("411001")
                .village("Shivajinagar")
                .landOwnership(Farm.LandOwnership.OWNED)
                .build();

        // When/Then
        mockMvc.perform(post("/farmer/profile/farms")
                        .header("X-User-Id", TEST_USER_ID.toString())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("farm with this name already exists")));
    }

    @Test
    @DisplayName("PUT /farmer/profile/farms/{farmId} - updates existing farm")
    void updateFarm_Success_ReturnsUpdatedFarm() throws Exception {
        // Given
        Farm savedFarm = farmRepository.save(testFarm);
        
        FarmRequest updateRequest = FarmRequest.builder()
                .farmName("Updated Farm Name")
                .farmType(Farm.FarmType.CONVENTIONAL)
                .totalAreaAcres(new BigDecimal("7.00"))
                .pincode("411001")
                .village("Shivajinagar")
                .soilType(Farm.SoilType.LOAMY)
                .irrigationType(Farm.IrrigationType.SPRINKLER)
                .landOwnership(Farm.LandOwnership.OWNED)
                .surveyNumber("123/45-A")
                .build();

        // When/Then
        mockMvc.perform(put("/farmer/profile/farms/" + savedFarm.getId())
                        .header("X-User-Id", TEST_USER_ID.toString())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Farm updated successfully")))
                .andExpect(jsonPath("$.data.farmName", is("Updated Farm Name")))
                .andExpect(jsonPath("$.data.farmType", is("CONVENTIONAL")))
                .andExpect(jsonPath("$.data.totalAreaAcres", is(7.00)));
    }

    @Test
    @DisplayName("DELETE /farmer/profile/farms/{farmId} - soft deletes farm")
    void deleteFarm_Success_Returns200() throws Exception {
        // Given
        Farm savedFarm = farmRepository.save(testFarm);

        // When/Then
        mockMvc.perform(delete("/farmer/profile/farms/" + savedFarm.getId())
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Farm deleted successfully")));

        // Verify soft delete
        Farm deletedFarm = farmRepository.findById(savedFarm.getId()).orElseThrow();
        org.assertj.core.api.Assertions.assertThat(deletedFarm.getIsActive()).isFalse();
    }

    @Test
    @DisplayName("GET /farmer/profile/farms/count - returns farm count")
    void getFarmCount_ReturnsCount() throws Exception {
        // Given
        farmRepository.save(testFarm);
        Farm farm2 = Farm.builder()
                .farmer(testFarmer)
                .farmName("Second Farm")
                .totalAreaAcres(new BigDecimal("3.00"))
                .pincode("411001")
                .village("Deccan")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .landOwnership(Farm.LandOwnership.LEASED)
                .isActive(true)
                .build();
        farmRepository.save(farm2);

        // When/Then
        mockMvc.perform(get("/farmer/profile/farms/count")
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Farm count retrieved successfully")))
                .andExpect(jsonPath("$.data", is(2)));
    }

    @Test
    @DisplayName("GET /farmer/profile/farms/collateral - returns valid collateral farms")
    void getValidCollateralFarms_ReturnsValidFarms() throws Exception {
        // Given
        // Farm 1: Valid collateral (verified, FREE, OWNED)
        testFarm.setIsVerified(true);
        testFarm.setEncumbranceStatus(Farm.EncumbranceStatus.FREE);
        testFarm.setLandOwnership(Farm.LandOwnership.OWNED);
        testFarm.setEstimatedLandValue(new BigDecimal("500000"));
        farmRepository.save(testFarm);
        
        // Farm 2: Invalid (not verified)
        Farm invalidFarm = Farm.builder()
                .farmer(testFarmer)
                .farmName("Unverified Farm")
                .totalAreaAcres(new BigDecimal("3.00"))
                .pincode("411001")
                .village("Deccan")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .landOwnership(Farm.LandOwnership.OWNED)
                .encumbranceStatus(Farm.EncumbranceStatus.FREE)
                .isVerified(false) // Not verified
                .isActive(true)
                .build();
        farmRepository.save(invalidFarm);

        // When/Then
        mockMvc.perform(get("/farmer/profile/farms/collateral")
                        .header("X-User-Id", TEST_USER_ID.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Valid collateral farms retrieved successfully")))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].farmName", is("Main Farm")))
                .andExpect(jsonPath("$.data[0].isVerified", is(true)));
    }

    @Test
    @DisplayName("GET /farmer/profile/farms - returns 400 when farmer profile not found")
    void getAllFarms_NoFarmerProfile_Returns400() throws Exception {
        // Given - user with no farmer profile
        Long nonExistentUserId = 999L;

        // When/Then
        mockMvc.perform(get("/farmer/profile/farms")
                        .header("X-User-Id", nonExistentUserId.toString()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Farmer profile not found")));
    }
}

