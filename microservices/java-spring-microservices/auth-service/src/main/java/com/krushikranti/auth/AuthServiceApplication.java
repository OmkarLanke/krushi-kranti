package com.krushikranti.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(exclude = {
        net.devh.boot.grpc.client.autoconfigure.GrpcClientAutoConfiguration.class,
        net.devh.boot.grpc.client.autoconfigure.GrpcClientHealthAutoConfiguration.class
})
@ComponentScan(basePackages = {"com.krushikranti.auth", "com.krushikranti.i18n"})
@EnableScheduling
public class AuthServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}

