package com.krushikranti.support.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddMessageRequest {

    @NotBlank
    private String content;
}

