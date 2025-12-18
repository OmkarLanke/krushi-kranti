package com.krushikranti.i18n.service;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.context.MessageSource;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.LocaleResolver;

import java.util.Locale;

/**
 * Service for retrieving internationalized messages.
 * Resolves locale from HTTP request and retrieves messages from MessageSource.
 */
@Service
@RequiredArgsConstructor
public class MessageService {

    private final MessageSource messageSource;
    private final LocaleResolver localeResolver;

    /**
     * Get a localized message by key using the locale from the HTTP request.
     * 
     * @param messageKey The message key (e.g., from MessageKeys constants)
     * @param request The HTTP request to extract locale from Accept-Language header
     * @return The localized message string
     */
    public String getMessage(String messageKey, HttpServletRequest request) {
        Locale locale = localeResolver.resolveLocale(request);
        return messageSource.getMessage(messageKey, null, locale);
    }

    /**
     * Get a localized message by key with arguments.
     * 
     * @param messageKey The message key
     * @param args Arguments to substitute in the message
     * @param request The HTTP request to extract locale from
     * @return The localized message string with substituted arguments
     */
    public String getMessage(String messageKey, Object[] args, HttpServletRequest request) {
        Locale locale = localeResolver.resolveLocale(request);
        return messageSource.getMessage(messageKey, args, locale);
    }

    /**
     * Get a localized message by key with default message if key not found.
     * 
     * @param messageKey The message key
     * @param defaultMessage Default message if key not found
     * @param request The HTTP request to extract locale from
     * @return The localized message string or default message
     */
    public String getMessage(String messageKey, String defaultMessage, HttpServletRequest request) {
        Locale locale = localeResolver.resolveLocale(request);
        return messageSource.getMessage(messageKey, null, defaultMessage, locale);
    }
}

