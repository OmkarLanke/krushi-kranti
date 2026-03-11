package com.krushikranti.jobapplication.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class FileForwardingService {

    private final WebClient.Builder webClientBuilder;

    @Value("${file.service.url:http://file-service:8080}")
    private String fileServiceUrl;

    /**
     * Forwards the multipart file to the existing file-service /file/upload endpoint.
     * Returns a Map response parsed from JSON (expects { message, data: { url, ... } })
     */
    public Mono<Map> forward(MultipartFile file, String folder, String fileName) {
        WebClient client = webClientBuilder.baseUrl(fileServiceUrl).build();

        MultipartBodyBuilder mb = new MultipartBodyBuilder();
        mb.part("file", file.getResource());
        if (folder != null) mb.part("folder", folder);
        if (fileName != null) mb.part("fileName", fileName);

        return client.post()
                .uri("/file/upload")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(mb.build()))
                .retrieve()
                .bodyToMono(Map.class);
    }
}

