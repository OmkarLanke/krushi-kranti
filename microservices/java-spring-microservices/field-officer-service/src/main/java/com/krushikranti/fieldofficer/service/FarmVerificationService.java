package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.dto.VerifyFarmRequest;
import com.krushikranti.fieldofficer.dto.VerifyFarmResponse;
import com.krushikranti.fieldofficer.model.FarmVerification;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import com.krushikranti.fieldofficer.repository.FarmVerificationRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerAssignmentRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Service for farm verification operations.
 * Handles verification of farms by field officers.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FarmVerificationService {

    private final FarmVerificationRepository verificationRepository;
    private final FieldOfficerRepository fieldOfficerRepository;
    private final FieldOfficerAssignmentRepository assignmentRepository;

    /**
     * Verify or reject a farm.
     * Validates that the field officer is assigned to the farm before allowing verification.
     */
    @Transactional
    public VerifyFarmResponse verifyFarm(VerifyFarmRequest request, Long fieldOfficerUserId) {
        log.info("Verifying farm {} by field officer userId {} with status: {}", 
                request.getFarmId(), fieldOfficerUserId, request.getStatus());

        // Validation 1: Find field officer by userId
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        // Validation 2: Check if field officer is assigned to this farm
        Optional<FieldOfficerAssignment> assignmentOpt = 
                assignmentRepository.findActiveAssignmentByFieldOfficerAndFarm(
                        fieldOfficer.getId(), request.getFarmId());

        if (assignmentOpt.isEmpty()) {
            throw new IllegalArgumentException(
                    "You are not assigned to farm ID: " + request.getFarmId() + 
                    ". Only assigned field officers can verify farms.");
        }

        // Validation 3: Validate status
        FarmVerification.VerificationStatus status;
        try {
            status = FarmVerification.VerificationStatus.valueOf(request.getStatus().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                    "Invalid verification status: " + request.getStatus() + 
                    ". Valid values are: VERIFIED, REJECTED, PENDING, IN_PROGRESS");
        }

        // Validation 4: If rejected, rejection reason or feedback should be provided
        if (status == FarmVerification.VerificationStatus.REJECTED) {
            if ((request.getRejectionReason() == null || request.getRejectionReason().trim().isEmpty()) &&
                (request.getFeedback() == null || request.getFeedback().trim().isEmpty())) {
                throw new IllegalArgumentException(
                        "Rejection reason or feedback is required when rejecting a farm.");
            }
        }

        // Check if verification already exists
        Optional<FarmVerification> existingVerification = 
                verificationRepository.findByFarmIdAndFieldOfficerId(
                        request.getFarmId(), fieldOfficer.getId());

        FarmVerification verification;
        if (existingVerification.isPresent()) {
            // Update existing verification
            verification = existingVerification.get();
            verification.setVerificationStatus(status);
            verification.setFeedback(request.getFeedback());
            verification.setRejectionReason(request.getRejectionReason());
            verification.setLatitude(request.getLatitude());
            verification.setLongitude(request.getLongitude());
            if (status == FarmVerification.VerificationStatus.VERIFIED || 
                status == FarmVerification.VerificationStatus.REJECTED) {
                verification.setVerifiedAt(LocalDateTime.now());
            }
            log.info("Updating existing verification ID: {}", verification.getId());
        } else {
            // Create new verification
            verification = FarmVerification.builder()
                    .farmId(request.getFarmId())
                    .fieldOfficerId(fieldOfficer.getId())
                    .verificationStatus(status)
                    .feedback(request.getFeedback())
                    .rejectionReason(request.getRejectionReason())
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .verifiedAt((status == FarmVerification.VerificationStatus.VERIFIED || 
                                status == FarmVerification.VerificationStatus.REJECTED) 
                            ? LocalDateTime.now() 
                            : null)
                    .build();
            log.info("Creating new verification for farm ID: {}", request.getFarmId());
        }

        FarmVerification saved = verificationRepository.save(verification);
        log.info("Farm verification saved successfully - ID: {}, Farm: {}, Status: {}", 
                saved.getId(), request.getFarmId(), status);

        return VerifyFarmResponse.builder()
                .verificationId(saved.getId())
                .farmId(saved.getFarmId())
                .fieldOfficerId(saved.getFieldOfficerId())
                .status(saved.getVerificationStatus().name())
                .feedback(saved.getFeedback())
                .rejectionReason(saved.getRejectionReason())
                .latitude(saved.getLatitude())
                .longitude(saved.getLongitude())
                .verifiedAt(saved.getVerifiedAt())
                .createdAt(saved.getCreatedAt())
                .updatedAt(saved.getUpdatedAt())
                .build();
    }

    /**
     * Get verification for a specific farm by the logged-in field officer.
     */
    public Optional<VerifyFarmResponse> getVerification(Long farmId, Long fieldOfficerUserId) {
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        Optional<FarmVerification> verification = 
                verificationRepository.findByFarmIdAndFieldOfficerId(farmId, fieldOfficer.getId());

        return verification.map(v -> VerifyFarmResponse.builder()
                .verificationId(v.getId())
                .farmId(v.getFarmId())
                .fieldOfficerId(v.getFieldOfficerId())
                .status(v.getVerificationStatus().name())
                .feedback(v.getFeedback())
                .rejectionReason(v.getRejectionReason())
                .latitude(v.getLatitude())
                .longitude(v.getLongitude())
                .verifiedAt(v.getVerifiedAt())
                .createdAt(v.getCreatedAt())
                .updatedAt(v.getUpdatedAt())
                .build());
    }
}

