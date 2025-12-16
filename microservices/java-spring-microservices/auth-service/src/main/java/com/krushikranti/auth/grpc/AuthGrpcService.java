package com.krushikranti.auth.grpc;

import com.krushikranti.auth.grpc.AuthServiceGrpc.AuthServiceImplBase;
import com.krushikranti.auth.grpc.AuthProto.*;
import com.krushikranti.auth.model.User;
import com.krushikranti.auth.repository.UserRepository;
import com.krushikranti.auth.service.JwtService;
import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.server.service.GrpcService;

import java.util.List;
import java.util.Optional;

@GrpcService
@RequiredArgsConstructor
@Slf4j
public class AuthGrpcService extends AuthServiceImplBase {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    @Override
    public void validateToken(TokenValidationRequest request, StreamObserver<TokenValidationResponse> responseObserver) {
        String token = request.getToken();
        
        boolean isValid = jwtService.validateToken(token);
        TokenValidationResponse.Builder responseBuilder = TokenValidationResponse.newBuilder()
                .setValid(isValid);

        if (isValid) {
            String userId = jwtService.getUserId(token);
            var roles = jwtService.getRoles(token);
            
            responseBuilder
                    .setUserId(userId != null ? userId : "")
                    .addAllRoles(roles);
        } else {
            responseBuilder.setErrorMessage("Invalid or expired token");
        }

        responseObserver.onNext(responseBuilder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void getUserInfo(TokenValidationRequest request, StreamObserver<UserInfoResponse> responseObserver) {
        String token = request.getToken();
        
        if (!jwtService.validateToken(token)) {
            responseObserver.onError(io.grpc.Status.UNAUTHENTICATED
                    .withDescription("Invalid token")
                    .asRuntimeException());
            return;
        }

        String userId = jwtService.getUserId(token);
        if (userId == null) {
            responseObserver.onError(io.grpc.Status.INVALID_ARGUMENT
                    .withDescription("User ID not found in token")
                    .asRuntimeException());
            return;
        }

        Optional<User> userOpt = userRepository.findById(Long.parseLong(userId));
        if (userOpt.isEmpty()) {
            responseObserver.onError(io.grpc.Status.NOT_FOUND
                    .withDescription("User not found")
                    .asRuntimeException());
            return;
        }

        User user = userOpt.get();
        var roles = jwtService.getRoles(token);

        UserInfoResponse response = UserInfoResponse.newBuilder()
                .setUserId(userId)
                .setUsername(user.getUsername())
                .setEmail(user.getEmail())
                .setPhoneNumber(user.getPhoneNumber())
                .addAllRoles(roles)
                .setActive(user.getIsActive())
                .build();

        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    @Override
    public void getUserById(GetUserByIdRequest request, StreamObserver<UserInfoResponse> responseObserver) {
        String userId = request.getUserId();
        
        if (userId == null || userId.isEmpty()) {
            responseObserver.onError(io.grpc.Status.INVALID_ARGUMENT
                    .withDescription("User ID is required")
                    .asRuntimeException());
            return;
        }

        try {
            Optional<User> userOpt = userRepository.findById(Long.parseLong(userId));
            if (userOpt.isEmpty()) {
                responseObserver.onError(io.grpc.Status.NOT_FOUND
                        .withDescription("User not found with ID: " + userId)
                        .asRuntimeException());
                return;
            }

            User user = userOpt.get();
            List<String> roles = List.of(user.getRole().name());

            UserInfoResponse response = UserInfoResponse.newBuilder()
                    .setUserId(userId)
                    .setUsername(user.getUsername())
                    .setEmail(user.getEmail())
                    .setPhoneNumber(user.getPhoneNumber())
                    .addAllRoles(roles)
                    .setActive(user.getIsActive())
                    .build();

            log.debug("Retrieved user info for userId: {}", userId);
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (NumberFormatException e) {
            responseObserver.onError(io.grpc.Status.INVALID_ARGUMENT
                    .withDescription("Invalid user ID format: " + userId)
                    .asRuntimeException());
        } catch (Exception e) {
            log.error("Error retrieving user by ID: {}", e.getMessage());
            responseObserver.onError(io.grpc.Status.INTERNAL
                    .withDescription("Internal server error")
                    .asRuntimeException());
        }
    }
}

