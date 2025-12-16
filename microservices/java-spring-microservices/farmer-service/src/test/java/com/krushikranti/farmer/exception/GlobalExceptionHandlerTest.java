package com.krushikranti.farmer.exception;

import com.krushikranti.farmer.dto.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@DisplayName("GlobalExceptionHandler Tests")
class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler exceptionHandler;

    @BeforeEach
    void setUp() {
        exceptionHandler = new GlobalExceptionHandler();
    }

    @Test
    @DisplayName("Handle IllegalArgumentException - returns 400")
    void handleIllegalArgumentException_ReturnsBadRequest() {
        // Given
        IllegalArgumentException exception = new IllegalArgumentException("Invalid pincode");

        // When
        ResponseEntity<ApiResponse<Object>> response = exceptionHandler.handleIllegalArgumentException(exception);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).isEqualTo("Invalid pincode");
        assertThat(response.getBody().getData()).isNull();
    }

    @Test
    @DisplayName("Handle MethodArgumentNotValidException - returns 400")
    void handleValidationException_ReturnsBadRequest() {
        // Given
        MethodArgumentNotValidException exception = mock(MethodArgumentNotValidException.class);
        BindingResult bindingResult = mock(BindingResult.class);
        
        FieldError fieldError1 = new FieldError("object", "firstName", "First name is required");
        FieldError fieldError2 = new FieldError("object", "email", "Email is required");
        
        when(exception.getBindingResult()).thenReturn(bindingResult);
        when(bindingResult.getFieldErrors()).thenReturn(List.of(fieldError1, fieldError2));

        // When
        ResponseEntity<ApiResponse<Object>> response = exceptionHandler.handleValidationException(exception);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Validation failed");
        assertThat(response.getBody().getMessage()).contains("firstName");
        assertThat(response.getBody().getMessage()).contains("email");
    }

    @Test
    @DisplayName("Handle RuntimeException - returns 500")
    void handleRuntimeException_ReturnsInternalServerError() {
        // Given
        RuntimeException exception = new RuntimeException("Database connection failed");

        // When
        ResponseEntity<ApiResponse<Object>> response = exceptionHandler.handleRuntimeException(exception);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("An error occurred");
        assertThat(response.getBody().getMessage()).contains("Database connection failed");
    }

    @Test
    @DisplayName("Handle generic Exception - returns 500")
    void handleException_ReturnsInternalServerError() {
        // Given
        Exception exception = new Exception("Unexpected error");

        // When
        ResponseEntity<ApiResponse<Object>> response = exceptionHandler.handleException(exception);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Internal server error");
        assertThat(response.getBody().getMessage()).contains("Unexpected error");
    }
}

