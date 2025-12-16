package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.service.PincodeImportService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PincodeImportController.class)
@DisplayName("PincodeImportController Tests")
class PincodeImportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PincodeImportService pincodeImportService;

    @Test
    @DisplayName("POST /farmer/admin/pincode/import - success")
    void importPincodes_Success_Returns200() throws Exception {
        // Given
        String filePath = "/path/to/excel.xlsx";
        int importedCount = 100;

        when(pincodeImportService.importFromExcel(filePath)).thenReturn(importedCount);

        // When/Then
        mockMvc.perform(post("/farmer/admin/pincode/import")
                        .param("filePath", filePath)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Pincode import completed successfully"))
                .andExpect(jsonPath("$.data").value(importedCount));
    }

    @Test
    @DisplayName("GET /farmer/admin/pincode/count - success")
    void getPincodeCount_Success_Returns200() throws Exception {
        // Given
        long count = 5000L;
        when(pincodeImportService.getPincodeCount()).thenReturn(count);

        // When/Then
        mockMvc.perform(get("/farmer/admin/pincode/count")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Pincode count retrieved"))
                .andExpect(jsonPath("$.data").value(count));
    }

    @Test
    @DisplayName("POST /farmer/admin/pincode/import - file not found")
    void importPincodes_FileNotFound_Returns500() throws Exception {
        // Given
        String filePath = "/path/to/nonexistent.xlsx";

        when(pincodeImportService.importFromExcel(filePath))
                .thenThrow(new RuntimeException("Failed to read Excel file: " + filePath));

        // When/Then
        mockMvc.perform(post("/farmer/admin/pincode/import")
                        .param("filePath", filePath)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError());
    }
}

