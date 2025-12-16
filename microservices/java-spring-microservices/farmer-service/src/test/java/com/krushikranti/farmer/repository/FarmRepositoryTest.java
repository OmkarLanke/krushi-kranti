package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@DisplayName("FarmRepository Tests")
class FarmRepositoryTest {

    @Autowired
    private FarmRepository farmRepository;

    @Autowired
    private FarmerRepository farmerRepository;

    private Farmer testFarmer;
    private Farm farm1;
    private Farm farm2;
    private Farm farm3;

    @BeforeEach
    void setUp() {
        farmRepository.deleteAll();
        farmerRepository.deleteAll();

        // Create test farmer
        testFarmer = Farmer.builder()
                .userId(100L)
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

        // Create test farms
        farm1 = Farm.builder()
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
                .isVerified(true)
                .isActive(true)
                .build();

        farm2 = Farm.builder()
                .farmer(testFarmer)
                .farmName("North Field")
                .farmType(Farm.FarmType.CONVENTIONAL)
                .totalAreaAcres(new BigDecimal("3.00"))
                .pincode("411002")
                .village("Deccan")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .landOwnership(Farm.LandOwnership.LEASED)
                .encumbranceStatus(Farm.EncumbranceStatus.NOT_VERIFIED)
                .isVerified(false)
                .isActive(true)
                .build();

        farm3 = Farm.builder()
                .farmer(testFarmer)
                .farmName("Deleted Farm")
                .totalAreaAcres(new BigDecimal("2.00"))
                .pincode("411003")
                .village("Kothrud")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .landOwnership(Farm.LandOwnership.OWNED)
                .isActive(false) // Soft deleted
                .build();
    }

    @Test
    @DisplayName("Find active farms by farmer ID")
    void findByFarmerIdAndIsActiveTrue_ReturnsActiveFarms() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2, farm3));

        // When
        List<Farm> result = farmRepository.findByFarmerIdAndIsActiveTrue(testFarmer.getId());

        // Then
        assertThat(result).hasSize(2);
        assertThat(result).extracting(Farm::getFarmName)
                .containsExactlyInAnyOrder("Main Farm", "North Field");
    }

    @Test
    @DisplayName("Find all farms by farmer ID (including inactive)")
    void findByFarmerId_ReturnsAllFarms() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2, farm3));

        // When
        List<Farm> result = farmRepository.findByFarmerId(testFarmer.getId());

        // Then
        assertThat(result).hasSize(3);
    }

    @Test
    @DisplayName("Find farm by ID and farmer ID")
    void findByIdAndFarmerId_ReturnsFarm() {
        // Given
        Farm savedFarm = farmRepository.save(farm1);

        // When
        Optional<Farm> result = farmRepository.findByIdAndFarmerId(savedFarm.getId(), testFarmer.getId());

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getFarmName()).isEqualTo("Main Farm");
    }

    @Test
    @DisplayName("Find active farm by ID and farmer ID")
    void findByIdAndFarmerIdAndIsActiveTrue_ReturnsActiveFarm() {
        // Given
        Farm savedFarm = farmRepository.save(farm1);
        farmRepository.save(farm3); // Inactive farm

        // When
        Optional<Farm> activeResult = farmRepository.findByIdAndFarmerIdAndIsActiveTrue(savedFarm.getId(), testFarmer.getId());
        Optional<Farm> inactiveResult = farmRepository.findByIdAndFarmerIdAndIsActiveTrue(farm3.getId(), testFarmer.getId());

        // Then
        assertThat(activeResult).isPresent();
        assertThat(inactiveResult).isEmpty();
    }

    @Test
    @DisplayName("Check farm name exists for farmer")
    void existsByFarmerIdAndFarmNameIgnoreCase_ReturnsTrueIfExists() {
        // Given
        farmRepository.save(farm1);

        // When
        boolean existsExact = farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(testFarmer.getId(), "Main Farm");
        boolean existsIgnoreCase = farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(testFarmer.getId(), "main farm");
        boolean notExists = farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(testFarmer.getId(), "Other Farm");

        // Then
        assertThat(existsExact).isTrue();
        assertThat(existsIgnoreCase).isTrue();
        assertThat(notExists).isFalse();
    }

    @Test
    @DisplayName("Check farm name exists excluding specific farm ID")
    void existsByFarmerIdAndFarmNameIgnoreCaseExcludingId_WorksCorrectly() {
        // Given
        Farm savedFarm1 = farmRepository.save(farm1);
        Farm savedFarm2 = farmRepository.save(farm2);

        // When - checking if "Main Farm" exists excluding farm1 (should be false)
        boolean excludingSelf = farmRepository.existsByFarmerIdAndFarmNameIgnoreCaseExcludingId(
                testFarmer.getId(), "Main Farm", savedFarm1.getId());
        
        // When - checking if "Main Farm" exists excluding farm2 (should be true, because farm1 has it)
        boolean excludingOther = farmRepository.existsByFarmerIdAndFarmNameIgnoreCaseExcludingId(
                testFarmer.getId(), "Main Farm", savedFarm2.getId());

        // Then
        assertThat(excludingSelf).isFalse();
        assertThat(excludingOther).isTrue();
    }

    @Test
    @DisplayName("Find verified farms")
    void findByFarmerIdAndIsVerifiedTrueAndIsActiveTrue_ReturnsVerifiedFarms() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2)); // farm1 is verified, farm2 is not

        // When
        List<Farm> result = farmRepository.findByFarmerIdAndIsVerifiedTrueAndIsActiveTrue(testFarmer.getId());

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getFarmName()).isEqualTo("Main Farm");
    }

    @Test
    @DisplayName("Find unverified farms")
    void findByFarmerIdAndIsVerifiedFalseAndIsActiveTrue_ReturnsUnverifiedFarms() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2));

        // When
        List<Farm> result = farmRepository.findByFarmerIdAndIsVerifiedFalseAndIsActiveTrue(testFarmer.getId());

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getFarmName()).isEqualTo("North Field");
    }

    @Test
    @DisplayName("Count active farms")
    void countByFarmerIdAndIsActiveTrue_ReturnsCorrectCount() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2, farm3));

        // When
        long count = farmRepository.countByFarmerIdAndIsActiveTrue(testFarmer.getId());

        // Then
        assertThat(count).isEqualTo(2);
    }

    @Test
    @DisplayName("Find farms by encumbrance status")
    void findByEncumbranceStatus_ReturnsFarmsWithStatus() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2));

        // When
        List<Farm> freeFarms = farmRepository.findByEncumbranceStatus(Farm.EncumbranceStatus.FREE);
        List<Farm> notVerifiedFarms = farmRepository.findByEncumbranceStatus(Farm.EncumbranceStatus.NOT_VERIFIED);

        // Then
        assertThat(freeFarms).hasSize(1);
        assertThat(freeFarms.get(0).getFarmName()).isEqualTo("Main Farm");
        assertThat(notVerifiedFarms).hasSize(1);
        assertThat(notVerifiedFarms.get(0).getFarmName()).isEqualTo("North Field");
    }

    @Test
    @DisplayName("Find valid collateral farms")
    void findValidCollateralFarms_ReturnsOnlyValidFarms() {
        // Given
        farmRepository.saveAll(List.of(farm1, farm2));
        // farm1 is: verified, FREE encumbrance, OWNED - valid collateral
        // farm2 is: not verified, NOT_VERIFIED encumbrance, LEASED - not valid

        // When
        List<Farm> result = farmRepository.findValidCollateralFarms(testFarmer.getId());

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getFarmName()).isEqualTo("Main Farm");
        assertThat(result.get(0).getIsVerified()).isTrue();
        assertThat(result.get(0).getEncumbranceStatus()).isEqualTo(Farm.EncumbranceStatus.FREE);
        assertThat(result.get(0).getLandOwnership()).isEqualTo(Farm.LandOwnership.OWNED);
    }

    @Test
    @DisplayName("Save and retrieve farm with all fields")
    void save_AllFields_PersistsCorrectly() {
        // Given
        Farm farmWithAllFields = Farm.builder()
                .farmer(testFarmer)
                .farmName("Complete Farm")
                .farmType(Farm.FarmType.MIXED)
                .totalAreaAcres(new BigDecimal("10.50"))
                .pincode("411001")
                .village("Shivajinagar")
                .district("Pune")
                .taluka("Pune")
                .state("Maharashtra")
                .soilType(Farm.SoilType.LOAMY)
                .irrigationType(Farm.IrrigationType.MIXED)
                .landOwnership(Farm.LandOwnership.GOVERNMENT_ALLOTTED)
                .surveyNumber("456/78")
                .landRegistrationNumber("REG-123-456")
                .pattaNumber("PAT-789")
                .estimatedLandValue(new BigDecimal("1500000.50"))
                .encumbranceStatus(Farm.EncumbranceStatus.PARTIALLY_ENCUMBERED)
                .encumbranceRemarks("Partial loan pending")
                .landDocumentUrl("https://s3.example.com/doc1.pdf")
                .surveyMapUrl("https://s3.example.com/map1.pdf")
                .registrationCertificateUrl("https://s3.example.com/cert1.pdf")
                .isVerified(true)
                .verifiedBy(999L)
                .verificationRemarks("Verified on field visit")
                .isActive(true)
                .build();

        // When
        Farm savedFarm = farmRepository.save(farmWithAllFields);
        Farm retrievedFarm = farmRepository.findById(savedFarm.getId()).orElseThrow();

        // Then
        assertThat(retrievedFarm.getFarmName()).isEqualTo("Complete Farm");
        assertThat(retrievedFarm.getFarmType()).isEqualTo(Farm.FarmType.MIXED);
        assertThat(retrievedFarm.getTotalAreaAcres()).isEqualByComparingTo(new BigDecimal("10.50"));
        assertThat(retrievedFarm.getSurveyNumber()).isEqualTo("456/78");
        assertThat(retrievedFarm.getLandRegistrationNumber()).isEqualTo("REG-123-456");
        assertThat(retrievedFarm.getPattaNumber()).isEqualTo("PAT-789");
        assertThat(retrievedFarm.getEstimatedLandValue()).isEqualByComparingTo(new BigDecimal("1500000.50"));
        assertThat(retrievedFarm.getEncumbranceStatus()).isEqualTo(Farm.EncumbranceStatus.PARTIALLY_ENCUMBERED);
        assertThat(retrievedFarm.getEncumbranceRemarks()).isEqualTo("Partial loan pending");
        assertThat(retrievedFarm.getLandDocumentUrl()).isEqualTo("https://s3.example.com/doc1.pdf");
        assertThat(retrievedFarm.getIsVerified()).isTrue();
        assertThat(retrievedFarm.getVerifiedBy()).isEqualTo(999L);
        assertThat(retrievedFarm.getCreatedAt()).isNotNull();
        assertThat(retrievedFarm.getUpdatedAt()).isNotNull();
    }
}

