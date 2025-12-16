package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.dto.FarmRequest;
import com.krushikranti.farmer.dto.FarmResponse;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmRepository;
import com.krushikranti.farmer.repository.FarmerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("FarmService Unit Tests")
class FarmServiceTest {

    @Mock
    private FarmRepository farmRepository;

    @Mock
    private FarmerRepository farmerRepository;

    @Mock
    private PincodeService pincodeService;

    @InjectMocks
    private FarmService farmService;

    private Farmer testFarmer;
    private Farm testFarm;
    private FarmRequest testFarmRequest;
    private AddressLookupResponse testAddressResponse;

    @BeforeEach
    void setUp() {
        testFarmer = Farmer.builder()
                .id(1L)
                .userId(100L)
                .firstName("John")
                .lastName("Doe")
                .build();

        testFarm = Farm.builder()
                .id(1L)
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
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        testFarmRequest = FarmRequest.builder()
                .farmName("Main Farm")
                .farmType(Farm.FarmType.ORGANIC)
                .totalAreaAcres(new BigDecimal("5.50"))
                .pincode("411001")
                .village("Shivajinagar")
                .soilType(Farm.SoilType.BLACK)
                .irrigationType(Farm.IrrigationType.DRIP)
                .landOwnership(Farm.LandOwnership.OWNED)
                .surveyNumber("123/45")
                .estimatedLandValue(new BigDecimal("500000"))
                .build();

        testAddressResponse = AddressLookupResponse.builder()
                .pincode("411001")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .villages(List.of("Shivajinagar", "Deccan", "Kothrud"))
                .build();
    }

    @Test
    @DisplayName("Get farms by user ID - success")
    void getFarmsByUserId_Success_ReturnsFarms() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.findByFarmerIdAndIsActiveTrue(1L)).thenReturn(List.of(testFarm));

        // When
        List<FarmResponse> result = farmService.getFarmsByUserId(100L);

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getFarmName()).isEqualTo("Main Farm");
        verify(farmerRepository).findByUserId(100L);
        verify(farmRepository).findByFarmerIdAndIsActiveTrue(1L);
    }

    @Test
    @DisplayName("Get farms by user ID - farmer not found")
    void getFarmsByUserId_FarmerNotFound_ThrowsException() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.empty());

        // When/Then
        assertThatThrownBy(() -> farmService.getFarmsByUserId(100L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Farmer profile not found");
    }

    @Test
    @DisplayName("Get farm by ID - success")
    void getFarmById_Success_ReturnsFarm() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.findByIdAndFarmerIdAndIsActiveTrue(1L, 1L)).thenReturn(Optional.of(testFarm));

        // When
        FarmResponse result = farmService.getFarmById(100L, 1L);

        // Then
        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getFarmName()).isEqualTo("Main Farm");
    }

    @Test
    @DisplayName("Get farm by ID - farm not found")
    void getFarmById_FarmNotFound_ThrowsException() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.findByIdAndFarmerIdAndIsActiveTrue(999L, 1L)).thenReturn(Optional.empty());

        // When/Then
        assertThatThrownBy(() -> farmService.getFarmById(100L, 999L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Farm not found");
    }

    @Test
    @DisplayName("Create farm - success")
    void createFarm_Success_ReturnsFarmResponse() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(1L, "Main Farm")).thenReturn(false);
        when(pincodeService.getAddressByPincode("411001")).thenReturn(testAddressResponse);
        when(farmRepository.save(any(Farm.class))).thenReturn(testFarm);

        // When
        FarmResponse result = farmService.createFarm(100L, testFarmRequest);

        // Then
        assertThat(result.getFarmName()).isEqualTo("Main Farm");
        assertThat(result.getDistrict()).isEqualTo("Pune");
        verify(farmRepository).save(any(Farm.class));
    }

    @Test
    @DisplayName("Create farm - duplicate name")
    void createFarm_DuplicateName_ThrowsException() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(1L, "Main Farm")).thenReturn(true);

        // When/Then
        assertThatThrownBy(() -> farmService.createFarm(100L, testFarmRequest))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("farm with this name already exists");
    }

    @Test
    @DisplayName("Create farm - invalid village for pincode")
    void createFarm_InvalidVillage_ThrowsException() {
        // Given
        FarmRequest requestWithInvalidVillage = FarmRequest.builder()
                .farmName("Test Farm")
                .totalAreaAcres(new BigDecimal("5.50"))
                .pincode("411001")
                .village("InvalidVillage")
                .landOwnership(Farm.LandOwnership.OWNED)
                .build();

        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(anyLong(), anyString())).thenReturn(false);
        when(pincodeService.getAddressByPincode("411001")).thenReturn(testAddressResponse);

        // When/Then
        assertThatThrownBy(() -> farmService.createFarm(100L, requestWithInvalidVillage))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Village 'InvalidVillage' is not valid for pincode");
    }

    @Test
    @DisplayName("Update farm - success")
    void updateFarm_Success_ReturnsFarmResponse() {
        // Given
        FarmRequest updateRequest = FarmRequest.builder()
                .farmName("Updated Farm")
                .farmType(Farm.FarmType.CONVENTIONAL)
                .totalAreaAcres(new BigDecimal("6.00"))
                .pincode("411001")
                .village("Shivajinagar")
                .landOwnership(Farm.LandOwnership.OWNED)
                .build();

        Farm updatedFarm = Farm.builder()
                .id(1L)
                .farmer(testFarmer)
                .farmName("Updated Farm")
                .farmType(Farm.FarmType.CONVENTIONAL)
                .totalAreaAcres(new BigDecimal("6.00"))
                .pincode("411001")
                .village("Shivajinagar")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .landOwnership(Farm.LandOwnership.OWNED)
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.findByIdAndFarmerIdAndIsActiveTrue(1L, 1L)).thenReturn(Optional.of(testFarm));
        when(farmRepository.existsByFarmerIdAndFarmNameIgnoreCaseExcludingId(1L, "Updated Farm", 1L)).thenReturn(false);
        when(pincodeService.getAddressByPincode("411001")).thenReturn(testAddressResponse);
        when(farmRepository.save(any(Farm.class))).thenReturn(updatedFarm);

        // When
        FarmResponse result = farmService.updateFarm(100L, 1L, updateRequest);

        // Then
        assertThat(result.getFarmName()).isEqualTo("Updated Farm");
        verify(farmRepository).save(any(Farm.class));
    }

    @Test
    @DisplayName("Delete farm - success (soft delete)")
    void deleteFarm_Success_SoftDeletes() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.findByIdAndFarmerIdAndIsActiveTrue(1L, 1L)).thenReturn(Optional.of(testFarm));
        when(farmRepository.save(any(Farm.class))).thenReturn(testFarm);

        // When
        farmService.deleteFarm(100L, 1L);

        // Then
        verify(farmRepository).save(argThat(farm -> !farm.getIsActive()));
    }

    @Test
    @DisplayName("Get farm count - success")
    void getFarmCount_Success_ReturnsCount() {
        // Given
        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.countByFarmerIdAndIsActiveTrue(1L)).thenReturn(5L);

        // When
        long count = farmService.getFarmCount(100L);

        // Then
        assertThat(count).isEqualTo(5L);
    }

    @Test
    @DisplayName("Get valid collateral farms - success")
    void getValidCollateralFarms_Success_ReturnsFarms() {
        // Given
        Farm collateralFarm = Farm.builder()
                .id(2L)
                .farmer(testFarmer)
                .farmName("Collateral Farm")
                .totalAreaAcres(new BigDecimal("10.00"))
                .pincode("411001")
                .village("Kothrud")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .landOwnership(Farm.LandOwnership.OWNED)
                .isVerified(true)
                .encumbranceStatus(Farm.EncumbranceStatus.FREE)
                .estimatedLandValue(new BigDecimal("1000000"))
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(farmerRepository.findByUserId(100L)).thenReturn(Optional.of(testFarmer));
        when(farmRepository.findValidCollateralFarms(1L)).thenReturn(List.of(collateralFarm));

        // When
        List<FarmResponse> result = farmService.getValidCollateralFarms(100L);

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getIsVerified()).isTrue();
        assertThat(result.get(0).getEncumbranceStatus()).isEqualTo(Farm.EncumbranceStatus.FREE);
    }
}

