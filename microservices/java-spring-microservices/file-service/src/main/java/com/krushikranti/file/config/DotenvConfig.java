package com.krushikranti.file.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.StandardEnvironment;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class DotenvConfig {

    @Bean
    public Dotenv dotenv(org.springframework.core.env.Environment environment) {
        // Try multiple locations for .env file
        String userDir = System.getProperty("user.dir");
        String[] possiblePaths = {
            "./.env",
            userDir + File.separator + ".env",
            userDir + File.separator + "file-service" + File.separator + ".env",
            "../.env",
            "microservices/java-spring-microservices/file-service/.env",
        };
        
        System.out.println("=== DotenvConfig: Looking for .env file ===");
        System.out.println("Current working directory: " + userDir);
        
        Dotenv dotenv = null;
        String loadedFrom = null;
        
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
                    System.out.println("✓ Loaded .env from: " + path);
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
                dotenv = Dotenv.configure()
                        .ignoreIfMissing()
                        .load();
                loadedFrom = "default location";
                System.out.println("✓ Loaded .env from default location");
            } catch (Exception e) {
                System.out.println("✗ .env file not found: " + e.getMessage());
                return null;
            }
        }
        
        if (dotenv != null) {
            // Set system properties AND add to Spring Environment
            Map<String, Object> envProperties = new HashMap<>();
            int loadedCount = 0;
            
            for (io.github.cdimascio.dotenv.DotenvEntry entry : dotenv.entries()) {
                String key = entry.getKey();
                String value = entry.getValue();
                
                // Only set if not already set as environment variable
                if (System.getenv(key) == null) {
                    // Set as system property
                    System.setProperty(key, value);
                    // Also add to Spring Environment property source
                    envProperties.put(key, value);
                    loadedCount++;
                    System.out.println("✓ Loaded from .env: " + key + " = " + (key.contains("SECRET") || key.contains("KEY") ? "***" : value));
                } else {
                    System.out.println("⊘ Skipped (already set as env var): " + key);
                }
            }
            
            // Add properties to Spring Environment so ${VAR} syntax can read them
            if (!envProperties.isEmpty() && environment instanceof StandardEnvironment) {
                StandardEnvironment stdEnv = (StandardEnvironment) environment;
                MutablePropertySources propertySources = stdEnv.getPropertySources();
                propertySources.addFirst(new MapPropertySource("dotenv", envProperties));
                System.out.println("✓ Added " + loadedCount + " properties to Spring Environment");
            }
            
            System.out.println("Total variables loaded from .env: " + loadedCount);
        }
        
        return dotenv;
    }
}

