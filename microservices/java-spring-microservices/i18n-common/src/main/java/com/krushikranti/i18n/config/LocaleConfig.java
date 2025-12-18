package com.krushikranti.i18n.config;

import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;

/**
 * Configuration for internationalization (i18n) support.
 * Configures MessageSource for property-based messages and LocaleResolver for request-based locale detection.
 */
@Configuration
public class LocaleConfig {

    /**
     * Configure MessageSource to load messages from properties files.
     * Supports: messages.properties (default), messages_hi.properties, messages_mr.properties
     */
    @Bean
    public MessageSource messageSource() {
        ResourceBundleMessageSource messageSource = new ResourceBundleMessageSource();
        messageSource.setBasename("messages");
        messageSource.setDefaultEncoding("UTF-8");
        messageSource.setUseCodeAsDefaultMessage(true); // Return key if message not found
        messageSource.setFallbackToSystemLocale(false); // Don't fall back to system locale
        return messageSource;
    }

    /**
     * Configure LocaleResolver to extract locale from Accept-Language HTTP header.
     * Supported locales: en (English), hi (Hindi), mr (Marathi)
     * Default locale: en (English)
     */
    @Bean
    public LocaleResolver localeResolver() {
        AcceptHeaderLocaleResolver localeResolver = new AcceptHeaderLocaleResolver();
        
        // Supported locales
        List<Locale> supportedLocales = Arrays.asList(
            Locale.forLanguageTag("en"), // English
            Locale.forLanguageTag("hi"), // Hindi
            Locale.forLanguageTag("mr")  // Marathi
        );
        localeResolver.setSupportedLocales(supportedLocales);
        
        // Default locale (used when Accept-Language header is missing or unsupported)
        localeResolver.setDefaultLocale(Locale.forLanguageTag("en"));
        
        return localeResolver;
    }
}

