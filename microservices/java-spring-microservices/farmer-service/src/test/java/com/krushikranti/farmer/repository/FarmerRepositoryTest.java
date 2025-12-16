package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Farmer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@DisplayName("FarmerRepository Tests")
class FarmerRepositoryTest {

    @Autowired
    private FarmerRepository farmerRepository;

    private Farmer testFarmer;

    @BeforeEach
    void setUp() {
        farmerRepository.deleteAll();
        
        testFarmer = Farmer.builder()
                .userId(1L)
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
    }

    @Test
    @DisplayName("Save farmer - success")
    void save_Success_ReturnsSavedFarmer() {
        // When
        Farmer saved = farmerRepository.save(testFarmer);

        // Then
        assertThat(saved).isNotNull();
        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getUserId()).isEqualTo(1L);
        assertThat(saved.getFirstName()).isEqualTo("John");
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
    }

    @Test
    @DisplayName("Find by userId - exists")
    void findByUserId_FarmerExists_ReturnsFarmer() {
        // Given
        farmerRepository.save(testFarmer);

        // When
        Optional<Farmer> found = farmerRepository.findByUserId(1L);

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getUserId()).isEqualTo(1L);
        assertThat(found.get().getFirstName()).isEqualTo("John");
    }

    @Test
    @DisplayName("Find by userId - not exists")
    void findByUserId_FarmerNotExists_ReturnsEmpty() {
        // When
        Optional<Farmer> found = farmerRepository.findByUserId(999L);

        // Then
        assertThat(found).isEmpty();
    }

    @Test
    @DisplayName("Update farmer - success")
    void update_Success_UpdatesFields() {
        // Given
        Farmer saved = farmerRepository.save(testFarmer);
        Long id = saved.getId();

        // When
        saved.setFirstName("Jane");
        saved.setLastName("Smith");
        Farmer updated = farmerRepository.save(saved);

        // Then
        assertThat(updated.getId()).isEqualTo(id);
        assertThat(updated.getFirstName()).isEqualTo("Jane");
        assertThat(updated.getLastName()).isEqualTo("Smith");
        // Note: In fast tests, updatedAt might equal createdAt, so we check it's at least equal or after
        assertThat(updated.getUpdatedAt()).isAfterOrEqualTo(updated.getCreatedAt());
    }

    @Test
    @DisplayName("Delete farmer - success")
    void delete_Success_RemovesFromDatabase() {
        // Given
        Farmer saved = farmerRepository.save(testFarmer);
        Long id = saved.getId();

        // When
        farmerRepository.delete(saved);

        // Then
        assertThat(farmerRepository.findById(id)).isEmpty();
    }
}

