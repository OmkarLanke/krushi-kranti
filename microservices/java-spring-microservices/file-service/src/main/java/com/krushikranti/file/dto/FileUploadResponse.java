package com.krushikranti.file.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FileUploadResponse {
    private String url;
    private String fileName;
    private Long fileSize;
    private String contentType;
}

