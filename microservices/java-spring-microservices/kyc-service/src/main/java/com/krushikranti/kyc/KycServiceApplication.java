package com.krushikranti.kyc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"com.krushikranti.kyc", "com.krushikranti.i18n"})
public class KycServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(KycServiceApplication.class, args);
    }
}

