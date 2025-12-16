package com.krushikranti.gateway.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
@ConfigurationProperties(prefix = "gateway.jwt")
@Data
public class GatewayJwtProperties {
    private boolean enabled = true;
    private List<String> skipPaths = new ArrayList<>();
    private String jwksUri;
}

