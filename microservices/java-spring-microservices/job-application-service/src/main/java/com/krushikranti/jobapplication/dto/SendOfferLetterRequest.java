package com.krushikranti.jobapplication.dto;

import lombok.Data;

/**
 * Request DTO for sending offer letter
 * Note: The actual PDF file will be sent as MultipartFile in the controller
 */
@Data
public class SendOfferLetterRequest {
    // Placeholder for any additional metadata if needed in future
    // The actual offer letter PDF will be handled as MultipartFile in controller
}
