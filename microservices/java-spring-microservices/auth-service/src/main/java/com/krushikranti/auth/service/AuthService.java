package com.krushikranti.auth.service;

import com.krushikranti.auth.dto.RegisterRequest;
import com.krushikranti.auth.model.User;
import com.krushikranti.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final OtpService otpService;
    private final RegistrationDataService registrationDataService;

    @Transactional
    public User registerUser(String username, String email, String phoneNumber, String password, User.UserRole role) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists");
        }
        if (userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Phone number already exists");
        }
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already exists");
        }

        User user = User.builder()
                .username(username)
                .email(email)
                .phoneNumber(phoneNumber)
                .passwordHash(passwordEncoder.encode(password))
                .role(role != null ? role : User.UserRole.FARMER)
                .isActive(true)
                .isVerified(false)
                .build();

        User savedUser = userRepository.save(user);
        log.info("User registered: {}", savedUser.getEmail());
        
        // Generate and send OTP (in production, send via SMS)
        otpService.generateOtp(phoneNumber);
        
        return savedUser;
    }

    public Optional<User> authenticate(String email, String password) {
        Optional<User> userOpt = userRepository.findByEmail(email);
        
        if (userOpt.isEmpty()) {
            return Optional.empty();
        }

        User user = userOpt.get();
        
        if (!user.getIsActive()) {
            log.warn("Attempt to login with inactive account: {}", email);
            return Optional.empty();
        }

        if (!user.getIsVerified()) {
            log.warn("Attempt to login with unverified account: {}", email);
            return Optional.empty();
        }

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            log.warn("Invalid password attempt for: {}", email);
            return Optional.empty();
        }

        return Optional.of(user);
    }

    public String generateToken(User user) {
        List<String> roles = List.of(user.getRole().name());
        return jwtService.generateToken(user.getId().toString(), user.getUsername(), roles);
    }

    /**
     * Send OTP for registration - validates user info and stores temporarily
     * User is NOT saved to database yet
     */
    public void sendRegistrationOtp(RegisterRequest registerRequest) {
        // Validate that user doesn't already exist
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            throw new IllegalArgumentException("Email already exists");
        }
        if (userRepository.existsByPhoneNumber(registerRequest.getPhoneNumber())) {
            throw new IllegalArgumentException("Phone number already exists");
        }
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            throw new IllegalArgumentException("Username already exists");
        }

        // Check if there's already a pending registration for this phone number
        RegisterRequest existingData = registrationDataService.getRegistrationData(registerRequest.getPhoneNumber());
        if (existingData != null) {
            log.info("Registration data already exists for phone: {}, overwriting", registerRequest.getPhoneNumber());
        }

        // Store registration data temporarily in Redis
        registrationDataService.storeRegistrationData(registerRequest.getPhoneNumber(), registerRequest);
        
        // Generate and send OTP
        otpService.generateOtp(registerRequest.getPhoneNumber());
        log.info("OTP sent for registration to phone: {}", registerRequest.getPhoneNumber());
    }

    /**
     * Verify OTP and complete registration - saves user to database with is_verified=true
     */
    @Transactional
    public User verifyOtpAndRegister(String phoneNumber, String otp) {
        // Verify OTP
        if (!otpService.validateOtp(phoneNumber, otp)) {
            throw new IllegalArgumentException("Invalid OTP");
        }

        // Retrieve registration data from Redis
        RegisterRequest registerRequest = registrationDataService.getRegistrationData(phoneNumber);
        if (registerRequest == null) {
            throw new IllegalArgumentException("Registration data not found. Please start registration again.");
        }

        // Verify again that user doesn't exist (in case registered between OTP send and verify)
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            registrationDataService.deleteRegistrationData(phoneNumber);
            throw new IllegalArgumentException("Email already exists");
        }
        if (userRepository.existsByPhoneNumber(phoneNumber)) {
            registrationDataService.deleteRegistrationData(phoneNumber);
            throw new IllegalArgumentException("Phone number already exists");
        }
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            registrationDataService.deleteRegistrationData(phoneNumber);
            throw new IllegalArgumentException("Username already exists");
        }

        // Create and save user with is_verified=true
        User user = User.builder()
                .username(registerRequest.getUsername())
                .email(registerRequest.getEmail())
                .phoneNumber(phoneNumber)
                .passwordHash(passwordEncoder.encode(registerRequest.getPassword()))
                .role(registerRequest.getRole() != null ? registerRequest.getRole() : User.UserRole.FARMER)
                .isActive(true)
                .isVerified(true) // User is verified since OTP is validated
                .build();

        User savedUser = userRepository.save(user);
        log.info("User registered and verified: {}", savedUser.getEmail());

        // Clean up registration data from Redis
        registrationDataService.deleteRegistrationData(phoneNumber);
        
        return savedUser;
    }

    @Transactional
    public void verifyUser(String phoneNumber, String otp) {
        if (!otpService.validateOtp(phoneNumber, otp)) {
            throw new IllegalArgumentException("Invalid OTP");
        }

        Optional<User> userOpt = userRepository.findByPhoneNumber(phoneNumber);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("User not found");
        }

        User user = userOpt.get();
        user.setIsVerified(true);
        userRepository.save(user);
        log.info("User verified: {}", phoneNumber);
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public Optional<User> findByPhoneNumber(String phoneNumber) {
        return userRepository.findByPhoneNumber(phoneNumber);
    }

    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    public String generateOtpForPhone(String phoneNumber) {
        return otpService.generateOtp(phoneNumber);
    }

    /**
     * Get OTP for a phone number (for testing purposes only)
     */
    public String getOtpForPhone(String phoneNumber) {
        return otpService.getOtp(phoneNumber);
    }

    /**
     * Send OTP for login - validates that user exists and is verified
     */
    public void sendLoginOtp(String phoneNumber) {
        Optional<User> userOpt = userRepository.findByPhoneNumber(phoneNumber);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("User not found with this phone number");
        }

        User user = userOpt.get();
        if (!user.getIsActive()) {
            throw new IllegalArgumentException("Account is inactive");
        }

        if (!user.getIsVerified()) {
            throw new IllegalArgumentException("Account is not verified. Please verify your account first.");
        }

        // Generate and send OTP for login
        otpService.generateOtp(phoneNumber);
        log.info("Login OTP sent to phone: {}", phoneNumber);
    }

    /**
     * Authenticate user with phone number and OTP
     */
    public Optional<User> authenticateWithOtp(String phoneNumber, String otp) {
        // Verify OTP
        if (!otpService.validateOtp(phoneNumber, otp)) {
            log.warn("Invalid OTP attempt for phone: {}", phoneNumber);
            return Optional.empty();
        }

        // Find user by phone number
        Optional<User> userOpt = userRepository.findByPhoneNumber(phoneNumber);
        if (userOpt.isEmpty()) {
            log.warn("User not found for phone: {}", phoneNumber);
            return Optional.empty();
        }

        User user = userOpt.get();

        if (!user.getIsActive()) {
            log.warn("Attempt to login with inactive account: {}", phoneNumber);
            return Optional.empty();
        }

        if (!user.getIsVerified()) {
            log.warn("Attempt to login with unverified account: {}", phoneNumber);
            return Optional.empty();
        }

        log.info("User authenticated successfully with OTP: {}", phoneNumber);
        return Optional.of(user);
    }

    /**
     * Admin method to create users directly without OTP verification.
     * Used by admin services to create field officers, etc.
     */
    @Transactional
    public User registerUserDirectly(String username, String email, String phoneNumber, String password, User.UserRole role) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists");
        }
        if (userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Phone number already exists");
        }
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already exists");
        }

        User user = User.builder()
                .username(username)
                .email(email)
                .phoneNumber(phoneNumber)
                .passwordHash(passwordEncoder.encode(password))
                .role(role != null ? role : User.UserRole.FARMER)
                .isActive(true)
                .isVerified(true) // Admin-created users are automatically verified
                .build();

        User savedUser = userRepository.save(user);
        log.info("User created directly by admin: {} (Role: {})", savedUser.getEmail(), savedUser.getRole());
        
        return savedUser;
    }
}

