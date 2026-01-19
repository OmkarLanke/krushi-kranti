package com.krushikranti.file.config;

import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

@Configuration
@ConfigurationProperties(prefix = "aws")
@Getter
@Setter
@Slf4j
@org.springframework.context.annotation.DependsOn("dotenv")
public class AwsS3Config {

    private String accessKeyId;
    private String secretAccessKey;
    private String region;
    private S3 s3 = new S3();

    @Getter
    @Setter
    public static class S3 {
        private String bucket;
        private String baseFolder = "";
    }

    @Bean
    public S3Client s3Client() {
        // Debug logging
        log.info("=== AWS S3 Configuration ===");
        log.info("Access Key ID: {}", accessKeyId != null ? (accessKeyId.length() > 10 ? accessKeyId.substring(0, 10) + "..." : accessKeyId) : "NULL");
        log.info("Secret Access Key: {}", secretAccessKey != null ? "SET (length: " + secretAccessKey.length() + ")" : "NULL");
        log.info("Region: {}", region);
        log.info("Bucket: {}", s3.getBucket());
        
        // Also print to System.out for visibility
        System.out.println("=== AWS S3 Configuration (Bean Creation) ===");
        System.out.println("Access Key ID: " + (accessKeyId != null ? (accessKeyId.length() > 10 ? accessKeyId.substring(0, 10) + "..." : accessKeyId) : "NULL"));
        System.out.println("Secret Access Key: " + (secretAccessKey != null ? "SET (length: " + secretAccessKey.length() + ")" : "NULL"));
        System.out.println("Region: " + region);
        System.out.println("Bucket: " + s3.getBucket());
        
        if (accessKeyId == null || accessKeyId.isEmpty()) {
            String errorMsg = "AWS Access Key ID is not configured. Please set AWS_ACCESS_KEY_ID environment variable or in .env file.";
            log.error(errorMsg);
            throw new IllegalStateException(errorMsg);
        }
        if (secretAccessKey == null || secretAccessKey.isEmpty()) {
            String errorMsg = "AWS Secret Access Key is not configured. Please set AWS_SECRET_ACCESS_KEY environment variable or in .env file.";
            log.error(errorMsg);
            throw new IllegalStateException(errorMsg);
        }
        
        AwsBasicCredentials awsCredentials = AwsBasicCredentials.create(
                accessKeyId,
                secretAccessKey
        );

        return S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(awsCredentials))
                .build();
    }
}

