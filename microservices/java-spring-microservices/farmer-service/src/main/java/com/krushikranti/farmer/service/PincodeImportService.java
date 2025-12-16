package com.krushikranti.farmer.service;

import com.krushikranti.farmer.model.PincodeMaster;
import com.krushikranti.farmer.repository.PincodeMasterRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

/**
 * Service for importing pincode data from Excel file.
 * This service reads the Excel file and populates the pincode_master table.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PincodeImportService {

    private final PincodeMasterRepository pincodeMasterRepository;

    /**
     * Import pincode data from Excel file.
     * Expected columns: Pincode, Village, Taluka, District, State
     * 
     * @param filePath Path to the Excel file
     * @return Number of records imported
     */
    @Transactional
    public int importFromExcel(String filePath) {
        log.info("Starting pincode import from file: {}", filePath);
        
        int importedCount = 0;
        int skippedCount = 0;
        Set<String> uniqueKeys = new HashSet<>();
        int[] columnMapping = null; // Will store: [pincodeIndex, villageIndex, talukaIndex, districtIndex, stateIndex]

        try (FileInputStream fis = new FileInputStream(filePath);
             Workbook workbook = new XSSFWorkbook(fis)) {

            Sheet sheet = workbook.getSheetAt(0); // First sheet
            
            // Detect column order from header row or sample rows
            columnMapping = detectColumnOrder(sheet);
            if (columnMapping == null) {
                log.error("Could not detect column order. Please check Excel file structure.");
                throw new RuntimeException("Could not detect column order in Excel file");
            }
            
            log.info("Detected column order - Pincode: {}, Village: {}, Taluka: {}, District: {}, State: {}",
                    columnMapping[0], columnMapping[1], columnMapping[2], columnMapping[3], columnMapping[4]);
            
            // Skip header row (row 0) and start from row 1
            for (int rowIndex = 1; rowIndex <= sheet.getLastRowNum(); rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) continue;

                try {
                    // Read columns using detected mapping
                    String pincode = getCellValueAsString(row.getCell(columnMapping[0]));
                    String village = getCellValueAsString(row.getCell(columnMapping[1]));
                    String taluka = getCellValueAsString(row.getCell(columnMapping[2]));
                    String district = getCellValueAsString(row.getCell(columnMapping[3]));
                    String state = getCellValueAsString(row.getCell(columnMapping[4]));

                    // Validate required fields
                    if (pincode == null || pincode.trim().isEmpty() ||
                        village == null || village.trim().isEmpty() ||
                        taluka == null || taluka.trim().isEmpty() ||
                        district == null || district.trim().isEmpty() ||
                        state == null || state.trim().isEmpty()) {
                        skippedCount++;
                        continue;
                    }

                    // Normalize pincode (remove spaces, ensure 6 digits)
                    pincode = pincode.trim().replaceAll("\\s+", "");
                    // Check if pincode is a valid 6-digit number
                    if (!pincode.matches("^[0-9]{6}$")) {
                        log.warn("Invalid pincode format at row {}: {}", rowIndex + 1, pincode);
                        skippedCount++;
                        continue;
                    }

                    // Create unique key to avoid duplicates
                    String uniqueKey = pincode + "|" + village.trim();
                    if (uniqueKeys.contains(uniqueKey)) {
                        skippedCount++;
                        continue;
                    }
                    uniqueKeys.add(uniqueKey);

                    // Check if already exists in database
                    boolean exists = pincodeMasterRepository.findByPincode(pincode)
                            .stream()
                            .anyMatch(p -> p.getVillage().equalsIgnoreCase(village.trim()));

                    if (!exists) {
                        PincodeMaster pincodeMaster = PincodeMaster.builder()
                                .pincode(pincode)
                                .village(village.trim())
                                .taluka(taluka.trim())
                                .district(district.trim())
                                .state(state.trim())
                                .build();

                        pincodeMasterRepository.save(pincodeMaster);
                        importedCount++;

                        if (importedCount % 1000 == 0) {
                            log.info("Imported {} records so far...", importedCount);
                        }
                    } else {
                        skippedCount++;
                    }

                } catch (Exception e) {
                    log.warn("Error processing row {}: {}", rowIndex + 1, e.getMessage());
                    skippedCount++;
                }
            }

            log.info("Pincode import completed. Imported: {}, Skipped: {}", importedCount, skippedCount);
            return importedCount;

        } catch (IOException e) {
            log.error("Error reading Excel file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to read Excel file: " + filePath, e);
        }
    }

    /**
     * Detect column order by analyzing header row and sample data rows.
     * Returns array: [pincodeIndex, villageIndex, talukaIndex, districtIndex, stateIndex]
     */
    private int[] detectColumnOrder(Sheet sheet) {
        Row headerRow = sheet.getRow(0);
        int maxColumns = 0;
        
        // Find maximum number of columns
        for (int i = 0; i <= Math.min(10, sheet.getLastRowNum()); i++) {
            Row row = sheet.getRow(i);
            if (row != null) {
                maxColumns = Math.max(maxColumns, row.getLastCellNum());
            }
        }
        
        if (maxColumns < 5) {
            log.warn("Excel file has less than 5 columns");
            return null;
        }
        
        int[] mapping = new int[5]; // [pincode, village, taluka, district, state]
        int[] pincodeColumnCandidates = new int[maxColumns];
        
        // Analyze first 20 data rows (after header) to find pincode column
        for (int rowIndex = 1; rowIndex <= Math.min(20, sheet.getLastRowNum()); rowIndex++) {
            Row row = sheet.getRow(rowIndex);
            if (row == null) continue;
            
            for (int colIndex = 0; colIndex < maxColumns; colIndex++) {
                String cellValue = getCellValueAsString(row.getCell(colIndex));
                if (cellValue != null && cellValue.trim().matches("^[0-9]{6}$")) {
                    pincodeColumnCandidates[colIndex]++;
                }
            }
        }
        
        // Find column with most 6-digit numeric values (likely pincode)
        int pincodeColumn = 0;
        int maxMatches = 0;
        for (int i = 0; i < maxColumns; i++) {
            if (pincodeColumnCandidates[i] > maxMatches) {
                maxMatches = pincodeColumnCandidates[i];
                pincodeColumn = i;
            }
        }
        
        if (maxMatches == 0) {
            log.error("Could not find pincode column (6-digit numbers)");
            return null;
        }
        
        mapping[0] = pincodeColumn;
        
        // Try to identify other columns from header if available
        if (headerRow != null) {
            String[] headerValues = new String[maxColumns];
            for (int i = 0; i < maxColumns; i++) {
                headerValues[i] = getCellValueAsString(headerRow.getCell(i));
                if (headerValues[i] != null) {
                    headerValues[i] = headerValues[i].trim().toLowerCase();
                }
            }
            
            // Try to match header names (case-insensitive, handle variations)
            for (int i = 0; i < maxColumns; i++) {
                if (i == pincodeColumn) continue;
                String header = headerValues[i];
                if (header == null) continue;
                
                // Village/Office Name - prioritize "office name" over just "office"
                if (mapping[1] == 0) {
                    if (header.contains("office name") || header.contains("village") || 
                        (header.contains("office") && !header.contains("status"))) {
                        mapping[1] = i;
                        continue;
                    }
                }
                
                // Taluka - handle both "taluk" (singular) and "taluka" (plural)
                if (mapping[2] == 0) {
                    if (header.contains("taluk") || header.contains("taluka") || 
                        header.contains("tehsil") || header.contains("block")) {
                        mapping[2] = i;
                        continue;
                    }
                }
                
                // District
                if (mapping[3] == 0 && header.contains("district")) {
                    mapping[3] = i;
                    continue;
                }
                
                // State - handle "state/u.t." format
                if (mapping[4] == 0 && (header.contains("state") || header.contains("u.t"))) {
                    mapping[4] = i;
                    continue;
                }
            }
        }
        
        // If header matching didn't work completely, fill remaining columns by position
        // Assume common format: columns are in order, just find which positions are used
        if (mapping[1] == 0 || mapping[2] == 0 || mapping[3] == 0 || mapping[4] == 0) {
            // Use simple heuristic: if pincode is in last column, assume reverse order
            // Otherwise assume standard order with pincode possibly shifted
            if (pincodeColumn >= maxColumns - 1) {
                // Pincode is last: State, District, Taluka, Village, Pincode
                if (mapping[4] == 0) mapping[4] = pincodeColumn == maxColumns - 1 ? maxColumns - 5 : maxColumns - 4;
                if (mapping[3] == 0) mapping[3] = maxColumns - 4;
                if (mapping[2] == 0) mapping[2] = maxColumns - 3;
                if (mapping[1] == 0) mapping[1] = maxColumns - 2;
            } else if (pincodeColumn == 0) {
                // Pincode is first: Pincode, Village, Taluka, District, State
                if (mapping[1] == 0) mapping[1] = 1;
                if (mapping[2] == 0) mapping[2] = 2;
                if (mapping[3] == 0) mapping[3] = 3;
                if (mapping[4] == 0) mapping[4] = 4;
            } else {
                // Pincode is in middle
                // Common format: Village(0), Status(1), Pincode(2), Phone(3), Taluka(4), District(5), State(6)
                // Or: Village(0), Pincode(1), Taluka(2), District(3), State(4)
                if (mapping[1] == 0) {
                    // Try column 0 first (most common for village/office name)
                    if (pincodeColumn > 0) {
                        mapping[1] = 0;
                    } else {
                        mapping[1] = pincodeColumn + 1;
                    }
                }
                if (mapping[2] == 0) {
                    // Taluka is usually after pincode, but might skip phone/status columns
                    // Try pincode + 2 first (skipping one column), then pincode + 1
                    if (pincodeColumn + 2 < maxColumns) {
                        mapping[2] = pincodeColumn + 2;
                    } else if (pincodeColumn + 1 < maxColumns) {
                        mapping[2] = pincodeColumn + 1;
                    }
                }
                if (mapping[3] == 0) {
                    // District is usually after taluka
                    if (mapping[2] > 0 && mapping[2] + 1 < maxColumns) {
                        mapping[3] = mapping[2] + 1;
                    } else if (pincodeColumn + 3 < maxColumns) {
                        mapping[3] = pincodeColumn + 3;
                    }
                }
                if (mapping[4] == 0) {
                    // State is usually last or after district
                    if (mapping[3] > 0 && mapping[3] + 1 < maxColumns) {
                        mapping[4] = mapping[3] + 1;
                    } else if (maxColumns > 0) {
                        mapping[4] = maxColumns - 1; // Assume last column
                    }
                }
            }
            
            // Ensure all mappings are valid
            for (int i = 0; i < 5; i++) {
                if (mapping[i] < 0 || mapping[i] >= maxColumns) {
                    log.error("Invalid column mapping detected. Pincode column: {}, Max columns: {}", pincodeColumn, maxColumns);
                    return null;
                }
            }
            
            // Ensure no duplicates
            for (int i = 0; i < 5; i++) {
                for (int j = i + 1; j < 5; j++) {
                    if (mapping[i] == mapping[j]) {
                        log.error("Duplicate column mapping detected");
                        return null;
                    }
                }
            }
        }
        
        return mapping;
    }
    
    private boolean contains(int[] array, int value) {
        for (int v : array) {
            if (v == value) return true;
        }
        return false;
    }

    /**
     * Get cell value as string, handling different cell types.
     */
    private String getCellValueAsString(Cell cell) {
        if (cell == null) {
            return null;
        }

        CellType cellType = cell.getCellType();
        
        if (cellType == CellType.STRING) {
            return cell.getStringCellValue();
        } else if (cellType == CellType.NUMERIC) {
            if (DateUtil.isCellDateFormatted(cell)) {
                return cell.getDateCellValue().toString();
            } else {
                // Convert numeric to string without decimal if it's a whole number
                double numericValue = cell.getNumericCellValue();
                if (numericValue == Math.floor(numericValue)) {
                    return String.valueOf((long) numericValue);
                } else {
                    return String.valueOf(numericValue);
                }
            }
        } else if (cellType == CellType.BOOLEAN) {
            return String.valueOf(cell.getBooleanCellValue());
        } else if (cellType == CellType.FORMULA) {
            return cell.getCellFormula();
        } else {
            return null;
        }
    }

    /**
     * Get count of pincode records in database.
     */
    public long getPincodeCount() {
        return pincodeMasterRepository.count();
    }
}

