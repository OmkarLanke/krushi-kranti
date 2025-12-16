package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.PincodeMaster;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@DisplayName("PincodeMasterRepository Tests")
class PincodeMasterRepositoryTest {

    @Autowired
    private PincodeMasterRepository pincodeMasterRepository;

    private PincodeMaster pincode1;
    private PincodeMaster pincode2;
    private PincodeMaster pincode3;

    @BeforeEach
    void setUp() {
        pincodeMasterRepository.deleteAll();

        pincode1 = PincodeMaster.builder()
                .pincode("411001")
                .village("Village1")
                .taluka("Pune")
                .district("Pune")
                .state("Maharashtra")
                .build();

        pincode2 = PincodeMaster.builder()
                .pincode("411001")
                .village("Village2")
                .taluka("Pune")
                .district("Pune")
                .state("Maharashtra")
                .build();

        pincode3 = PincodeMaster.builder()
                .pincode("411002")
                .village("Village3")
                .taluka("Pune")
                .district("Pune")
                .state("Maharashtra")
                .build();
    }

    @Test
    @DisplayName("Find by pincode - multiple villages")
    void findByPincode_MultipleVillages_ReturnsAll() {
        // Given
        pincodeMasterRepository.save(pincode1);
        pincodeMasterRepository.save(pincode2);
        pincodeMasterRepository.save(pincode3);

        // When
        List<PincodeMaster> found = pincodeMasterRepository.findByPincode("411001");

        // Then
        assertThat(found).hasSize(2);
        assertThat(found).extracting(PincodeMaster::getVillage)
                .containsExactlyInAnyOrder("Village1", "Village2");
    }

    @Test
    @DisplayName("Find district by pincode - exists")
    void findDistrictsByPincode_Exists_ReturnsDistrict() {
        // Given
        pincodeMasterRepository.save(pincode1);

        // When
        List<String> districts = pincodeMasterRepository.findDistrictsByPincode("411001");

        // Then
        assertThat(districts).isNotEmpty();
        assertThat(districts).containsExactly("Pune");
    }

    @Test
    @DisplayName("Find district by pincode - not exists")
    void findDistrictsByPincode_NotExists_ReturnsEmpty() {
        // When
        List<String> districts = pincodeMasterRepository.findDistrictsByPincode("999999");

        // Then
        assertThat(districts).isEmpty();
    }

    @Test
    @DisplayName("Find taluka by pincode - exists")
    void findTalukasByPincode_Exists_ReturnsTaluka() {
        // Given
        pincodeMasterRepository.save(pincode1);

        // When
        List<String> talukas = pincodeMasterRepository.findTalukasByPincode("411001");

        // Then
        assertThat(talukas).isNotEmpty();
        assertThat(talukas).containsExactly("Pune");
    }

    @Test
    @DisplayName("Find state by pincode - exists")
    void findStatesByPincode_Exists_ReturnsState() {
        // Given
        pincodeMasterRepository.save(pincode1);

        // When
        List<String> states = pincodeMasterRepository.findStatesByPincode("411001");

        // Then
        assertThat(states).isNotEmpty();
        assertThat(states).containsExactly("Maharashtra");
    }

    @Test
    @DisplayName("Find villages by pincode - multiple villages")
    void findVillagesByPincode_MultipleVillages_ReturnsAllVillages() {
        // Given
        pincodeMasterRepository.save(pincode1);
        pincodeMasterRepository.save(pincode2);

        // When
        List<String> villages = pincodeMasterRepository.findVillagesByPincode("411001");

        // Then
        assertThat(villages).hasSize(2);
        assertThat(villages).containsExactlyInAnyOrder("Village1", "Village2");
    }

    @Test
    @DisplayName("Find villages by pincode - not exists")
    void findVillagesByPincode_NotExists_ReturnsEmptyList() {
        // When
        List<String> villages = pincodeMasterRepository.findVillagesByPincode("999999");

        // Then
        assertThat(villages).isEmpty();
    }
}

