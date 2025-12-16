package com.krushikranti.farmer.service;

import com.krushikranti.auth.grpc.AuthServiceGrpc;
import com.krushikranti.auth.grpc.GetUserByIdRequest;
import com.krushikranti.auth.grpc.UserInfoResponse;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.client.inject.GrpcClient;
import org.springframework.stereotype.Service;

/**
 * gRPC Client to call Auth Service for user information.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceClient {

    @GrpcClient("auth-service")
    private AuthServiceGrpc.AuthServiceBlockingStub authServiceStub;

    /**
     * Get user information by user ID from Auth Service.
     * 
     * @param userId The user ID
     * @return UserInfoResponse containing email, phone, username, etc.
     * @throws RuntimeException if user not found or gRPC call fails
     */
    public UserInfoResponse getUserById(String userId) {
        try {
            GetUserByIdRequest request = GetUserByIdRequest.newBuilder()
                    .setUserId(userId)
                    .build();

            UserInfoResponse response = authServiceStub.getUserById(request);
            log.debug("Retrieved user info for userId: {}", userId);
            return response;
        } catch (StatusRuntimeException e) {
            if (e.getStatus().getCode() == Status.Code.NOT_FOUND) {
                log.warn("User not found with ID: {}", userId);
                throw new RuntimeException("User not found with ID: " + userId, e);
            } else {
                log.error("Error calling Auth Service for userId {}: {}", userId, e.getMessage());
                throw new RuntimeException("Failed to retrieve user information from Auth Service", e);
            }
        }
    }
}

