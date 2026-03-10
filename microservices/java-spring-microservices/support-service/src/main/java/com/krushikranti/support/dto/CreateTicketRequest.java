package com.krushikranti.support.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateTicketRequest {

    @NotBlank
    @Size(max = 200)
    private String title;

    @Size(max = 100)
    private String category;

    @NotBlank
    private String description;
}

