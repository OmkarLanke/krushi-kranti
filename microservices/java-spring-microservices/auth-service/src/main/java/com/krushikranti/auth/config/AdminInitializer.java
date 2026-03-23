package com.krushikranti.auth.config;

import com.krushikranti.auth.model.User;
import com.krushikranti.auth.model.User.UserRole;
import com.krushikranti.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Initializes the default admin user on application startup.
 * Reads credentials from environment variables.
 * Only creates admin if it doesn't already exist.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AdminInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.admin.username}")
    private String adminUsername;

    @Value("${app.admin.email}")
    private String adminEmail;

    @Value("${app.admin.phone}")
    private String adminPhone;

    @Value("${app.admin.password}")
    private String adminPassword;

    @Override
    public void run(String... args) {
        initializeAdminUser();
    }

    private void initializeAdminUser() {
        // Check if admin user already exists
        if (userRepository.existsByUsername(adminUsername)) {
            log.info("Admin user '{}' already exists, skipping initialization", adminUsername);
            return;
        }

        // Check if email is already taken
        if (userRepository.existsByEmail(adminEmail)) {
            log.warn("Email '{}' already exists, cannot create admin user", adminEmail);
            return;
        }

        try {
            User admin = User.builder()
                    .username(adminUsername)
                    .email(adminEmail)
                    .phoneNumber(adminPhone)
                    .passwordHash(passwordEncoder.encode(adminPassword))
                    .role(UserRole.ADMIN)
                    .isActive(true)
                    .isVerified(true)
                    .build();

            userRepository.save(admin);
            log.info("Admin user '{}' created successfully", adminUsername);
        } catch (Exception e) {
            log.error("Failed to create admin user: {}", e.getMessage());
        }
    }
}
