package com.krushikranti.farmer.config;

import io.netty.channel.ChannelOption;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;

@Configuration
public class DataGovApiConfig {

    @Value("${datagovin.api.base-url:https://api.data.gov.in/resource}")
    private String baseUrl;

    @Value("${datagovin.api.timeout:15000}")
    private int timeoutMs;

    @Bean(name = "dataGovWebClient")
    public WebClient dataGovWebClient() {
        HttpClient httpClient = HttpClient.create()
                .responseTimeout(Duration.ofMillis(timeoutMs))
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, timeoutMs);

        return WebClient.builder()
                .baseUrl(baseUrl)
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader("Accept", "application/json")
                .codecs(configurer -> configurer
                        .defaultCodecs()
                        .maxInMemorySize(2 * 1024 * 1024))
                .build();
    }
}
