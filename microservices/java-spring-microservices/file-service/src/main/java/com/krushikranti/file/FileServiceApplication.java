package com.krushikranti.file;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.File;

@SpringBootApplication
public class FileServiceApplication {

    public static void main(String[] args) {
        // Load .env file if it exists (for local development)
        // Environment variables set in system/Docker will take precedence
        
        // Try multiple locations for .env file
        // When running with mvn spring-boot:run, working dir might be parent directory
        String userDir = System.getProperty("user.dir");
        String[] possiblePaths = {
            "./.env",                                    // Current directory
            userDir + File.separator + ".env",           // Working directory
            userDir + File.separator + "file-service" + File.separator + ".env",  // file-service subdirectory
            "../.env",                                   // Parent directory
            "microservices/java-spring-microservices/file-service/.env",  // From project root
        };
        
        Dotenv dotenv = null;
        String loadedFrom = null;
        
        System.out.println("=== Looking for .env file ===");
        System.out.println("Current working directory: " + System.getProperty("user.dir"));
        
        for (String path : possiblePaths) {
            try {
                File envFile = new File(path);
                System.out.println("Checking: " + path + " -> exists: " + envFile.exists());
                if (envFile.exists()) {
                    dotenv = Dotenv.configure()
                            .filename(".env")
                            .directory(envFile.getParent())
                            .ignoreIfMissing()
                            .load();
                    loadedFrom = path;
                    System.out.println("✓ Found .env file at: " + path);
                    break;
                }
            } catch (Exception e) {
                System.out.println("Error checking " + path + ": " + e.getMessage());
                continue;
            }
        }
        
        // If still not found, try default location
        if (dotenv == null) {
            try {
                System.out.println("Trying default location...");
                dotenv = Dotenv.configure()
                        .ignoreIfMissing()
                        .load();
                loadedFrom = "default location";
                System.out.println("✓ Loaded from default location");
            } catch (Exception e) {
                System.out.println("✗ .env file not found in any location: " + e.getMessage());
            }
        }
        
        if (dotenv != null) {
            System.out.println("=== Loading .env file from: " + loadedFrom + " ===");
            
            // Set system properties from .env file
            // Spring Boot's ${VAR} syntax reads from environment variables first, then system properties
            int loadedCount = 0;
            for (io.github.cdimascio.dotenv.DotenvEntry entry : dotenv.entries()) {
                String key = entry.getKey();
                String value = entry.getValue();
                // Check if already set as environment variable
                if (System.getenv(key) == null) {
                    // Set as system property - Spring Boot will read this via ${VAR} syntax
                    System.setProperty(key, value);
                    loadedCount++;
                    System.out.println("✓ Loaded from .env: " + key + " = " + (key.contains("SECRET") || key.contains("KEY") ? "***" : value));
                } else {
                    System.out.println("⊘ Skipped (already set as env var): " + key);
                }
            }
            System.out.println("Total variables loaded from .env: " + loadedCount);
        }
        
        // Debug: Print what Spring Boot will see
        System.out.println("\n=== Environment Variables Check (Before Spring Boot starts) ===");
        String accessKeyEnv = System.getenv("AWS_ACCESS_KEY_ID");
        String accessKeyProp = System.getProperty("AWS_ACCESS_KEY_ID");
        String secretKeyEnv = System.getenv("AWS_SECRET_ACCESS_KEY");
        String secretKeyProp = System.getProperty("AWS_SECRET_ACCESS_KEY");
        
        System.out.println("AWS_ACCESS_KEY_ID (env): " + (accessKeyEnv != null ? "SET (length: " + accessKeyEnv.length() + ", value: " + accessKeyEnv.substring(0, Math.min(10, accessKeyEnv.length())) + "...)" : "NOT SET"));
        System.out.println("AWS_ACCESS_KEY_ID (property): " + (accessKeyProp != null ? "SET (length: " + accessKeyProp.length() + ", value: " + accessKeyProp.substring(0, Math.min(10, accessKeyProp.length())) + "...)" : "NOT SET"));
        System.out.println("AWS_SECRET_ACCESS_KEY (env): " + (secretKeyEnv != null ? "SET (length: " + secretKeyEnv.length() + ")" : "NOT SET"));
        System.out.println("AWS_SECRET_ACCESS_KEY (property): " + (secretKeyProp != null ? "SET (length: " + secretKeyProp.length() + ")" : "NOT SET"));
        System.out.println("===========================================\n");
        
        SpringApplication.run(FileServiceApplication.class, args);
    }
}

