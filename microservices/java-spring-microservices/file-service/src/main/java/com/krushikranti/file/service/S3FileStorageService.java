package com.krushikranti.file.service;

import com.krushikranti.file.config.AwsS3Config;
import com.krushikranti.file.dto.FileUploadResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.io.IOException;
import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class S3FileStorageService {

    private final S3Client s3Client;
    private final AwsS3Config awsS3Config;

    /**
     * Upload a file to S3 bucket
     * 
     * @param file The multipart file to upload
     * @param folder Optional folder path within the bucket (e.g., "farm-verifications")
     * @param fileName Optional custom file name. If not provided, generates a unique name
     * @return FileUploadResponse containing the S3 URL and metadata
     * @throws IOException if file reading fails
     * @throws S3Exception if S3 upload fails
     */
    public FileUploadResponse uploadFile(MultipartFile file, String folder, String fileName) throws IOException {
        try {
            // Validate file
            if (file == null || file.isEmpty()) {
                throw new IllegalArgumentException("File cannot be empty");
            }

            // Generate file name if not provided
            String finalFileName = fileName != null && !fileName.isEmpty() 
                    ? fileName 
                    : generateFileName(file.getOriginalFilename());

            // Build S3 key (path)
            String s3Key = buildS3Key(folder, finalFileName);

            // Get bucket name
            String bucketName = awsS3Config.getS3().getBucket();

            log.info("Uploading file to S3: bucket={}, key={}, size={} bytes", 
                    bucketName, s3Key, file.getSize());

            // Upload to S3
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .contentType(file.getContentType())
                    .contentLength(file.getSize())
                    .build();

            s3Client.putObject(putObjectRequest, 
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            // Generate S3 URL
            String fileUrl = generateS3Url(bucketName, s3Key);

            log.info("File uploaded successfully to S3: {}", fileUrl);

            return new FileUploadResponse(
                    fileUrl,
                    finalFileName,
                    file.getSize(),
                    file.getContentType()
            );

        } catch (S3Exception e) {
            log.error("S3 upload failed: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to upload file to S3: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("File upload error: {}", e.getMessage(), e);
            throw new RuntimeException("File upload failed: " + e.getMessage(), e);
        }
    }

    /**
     * Generate a unique file name
     */
    private String generateFileName(String originalFilename) {
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        } else {
            extension = ".jpg"; // Default extension
        }
        return UUID.randomUUID().toString() + "_" + Instant.now().toEpochMilli() + extension;
    }

    /**
     * Build S3 key (path) from folder and file name
     */
    private String buildS3Key(String folder, String fileName) {
        String baseFolder = awsS3Config.getS3().getBaseFolder();
        StringBuilder keyBuilder = new StringBuilder();
        
        if (baseFolder != null && !baseFolder.isEmpty()) {
            keyBuilder.append(baseFolder);
            if (!baseFolder.endsWith("/")) {
                keyBuilder.append("/");
            }
        }
        
        if (folder != null && !folder.isEmpty()) {
            keyBuilder.append(folder);
            if (!folder.endsWith("/")) {
                keyBuilder.append("/");
            }
        }
        
        keyBuilder.append(fileName);
        
        return keyBuilder.toString();
    }

    /**
     * Generate S3 URL for the uploaded file
     * Format: https://{bucket}.s3.{region}.amazonaws.com/{key}
     */
    private String generateS3Url(String bucketName, String key) {
        String region = awsS3Config.getRegion();
        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucketName, region, key);
    }
}

