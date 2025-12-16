package com.krushikranti.farmer.service;

import com.krushikranti.auth.grpc.AuthServiceGrpc;
import com.krushikranti.auth.grpc.GetUserByIdRequest;
import com.krushikranti.auth.grpc.UserInfoResponse;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthServiceClient Unit Tests")
class AuthServiceClientTest {

    @Mock
    private AuthServiceGrpc.AuthServiceBlockingStub authServiceStub;

    @InjectMocks
    private AuthServiceClient authServiceClient;

    private String userId;
    private UserInfoResponse userInfoResponse;

    @BeforeEach
    void setUp() {
        // Use reflection to set the private field
        try {
            var field = AuthServiceClient.class.getDeclaredField("authServiceStub");
            field.setAccessible(true);
            field.set(authServiceClient, authServiceStub);
        } catch (Exception e) {
            throw new RuntimeException("Failed to set mock stub", e);
        }

        userId = "1";
        userInfoResponse = UserInfoResponse.newBuilder()
                .setUserId(userId)
                .setEmail("farmer@example.com")
                .setPhoneNumber("9876543210")
                .setUsername("farmer1")
                .addAllRoles(List.of("FARMER"))
                .setActive(true)
                .build();
    }

    @Test
    @DisplayName("Get user by id - success")
    void getUserById_Success_ReturnsUserInfoResponse() {
        // Given
        when(authServiceStub.getUserById(any(GetUserByIdRequest.class)))
                .thenReturn(userInfoResponse);

        // When
        UserInfoResponse response = authServiceClient.getUserById(userId);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getUserId()).isEqualTo(userId);
        assertThat(response.getEmail()).isEqualTo("farmer@example.com");
        assertThat(response.getPhoneNumber()).isEqualTo("9876543210");
        assertThat(response.getUsername()).isEqualTo("farmer1");
        assertThat(response.getActive()).isTrue();

        verify(authServiceStub).getUserById(any(GetUserByIdRequest.class));
    }

    @Test
    @DisplayName("Get user by id - user not found")
    void getUserById_UserNotFound_ThrowsRuntimeException() {
        // Given
        StatusRuntimeException notFoundException = Status.NOT_FOUND
                .withDescription("User not found")
                .asRuntimeException();

        when(authServiceStub.getUserById(any(GetUserByIdRequest.class)))
                .thenThrow(notFoundException);

        // When/Then
        assertThatThrownBy(() -> authServiceClient.getUserById(userId))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("User not found with ID: " + userId);

        verify(authServiceStub).getUserById(any(GetUserByIdRequest.class));
    }

    @Test
    @DisplayName("Get user by id - gRPC error")
    void getUserById_GrpcError_ThrowsRuntimeException() {
        // Given
        StatusRuntimeException grpcException = Status.INTERNAL
                .withDescription("Internal server error")
                .asRuntimeException();

        when(authServiceStub.getUserById(any(GetUserByIdRequest.class)))
                .thenThrow(grpcException);

        // When/Then
        assertThatThrownBy(() -> authServiceClient.getUserById(userId))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to retrieve user information from Auth Service");

        verify(authServiceStub).getUserById(any(GetUserByIdRequest.class));
    }
}

