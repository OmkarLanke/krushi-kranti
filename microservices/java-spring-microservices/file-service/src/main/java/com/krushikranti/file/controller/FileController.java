package com.krushikranti.file.controller;

import com.krushikranti.file.dto.ApiResponse;
import com.krushikranti.file.dto.FileUploadResponse;
import com.krushikranti.file.service.S3FileStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/file")
@RequiredArgsConstructor
@Slf4j
public class FileController {

    private final S3FileStorageService fileStorageService;

    /**
     * Upload a file to S3
     * 
     * POST /file/upload
     * 
     * @param file Multipart file (required)
     * @param folder Optional folder path (e.g., "farm-verifications")
     * @param fileName Optional custom file name
     * @return ApiResponse with FileUploadResponse containing the file URL
     */
    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<FileUploadResponse>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folder", required = false) String folder,
            @RequestParam(value = "fileName", required = false) String fileName) {
        
        try {
            log.info("File upload request received: fileName={}, folder={}, size={} bytes", 
                    file.getOriginalFilename(), folder, file.getSize());

            // Validate file
            if (file == null || file.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("File cannot be empty", null));
            }

            // Upload to S3
            FileUploadResponse uploadResponse = fileStorageService.uploadFile(file, folder, fileName);

            log.info("File uploaded successfully: {}", uploadResponse.getUrl());

            return ResponseEntity.status(HttpStatus.OK)
                    .body(new ApiResponse<>("File uploaded successfully", uploadResponse));

        } catch (IllegalArgumentException e) {
            log.warn("Invalid file upload request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("File upload failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("File upload failed: " + e.getMessage(), null));
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(new ApiResponse<>("File service is running", "OK"));
    }
}

