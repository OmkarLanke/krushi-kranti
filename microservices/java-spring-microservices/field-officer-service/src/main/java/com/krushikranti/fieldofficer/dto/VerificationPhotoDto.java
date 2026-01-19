package com.krushikranti.fieldofficer.dto;

import com.krushikranti.fieldofficer.model.VerificationPhoto;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for verification photo response
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerificationPhotoDto {
    
    private Long photoId;
    private Long verificationId;
    private String photoUrl;
    private String photoType;
    private String description;
    private LocalDateTime uploadedAt;
    
    public static VerificationPhotoDto fromEntity(VerificationPhoto photo) {
        return VerificationPhotoDto.builder()
                .photoId(photo.getId())
                .verificationId(photo.getVerificationId())
                .photoUrl(photo.getPhotoUrl())
                .photoType(photo.getPhotoType() != null ? photo.getPhotoType().name() : null)
                .description(photo.getDescription())
                .uploadedAt(photo.getUploadedAt())
                .build();
    }
}
