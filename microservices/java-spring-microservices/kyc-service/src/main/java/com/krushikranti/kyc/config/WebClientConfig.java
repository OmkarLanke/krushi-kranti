package com.krushikranti.kyc.config;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * WebClient configuration for Quick eKYC API calls.
 */
@Configuration
@RequiredArgsConstructor
public class WebClientConfig {

    private final QuickEkycConfig quickEkycConfig;

    @Bean
    public WebClient quickEkycWebClient() {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, quickEkycConfig.getConnectTimeout())
                .responseTimeout(Duration.ofMillis(quickEkycConfig.getReadTimeout()))
                .doOnConnected(conn -> conn
                        .addHandlerLast(new ReadTimeoutHandler(quickEkycConfig.getReadTimeout(), TimeUnit.MILLISECONDS))
                        .addHandlerLast(new WriteTimeoutHandler(quickEkycConfig.getConnectTimeout(), TimeUnit.MILLISECONDS)));

        return WebClient.builder()
                .baseUrl(quickEkycConfig.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader("Content-Type", "application/json")
                .build();
    }
}

