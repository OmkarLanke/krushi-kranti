package com.krushikranti.subscription.grpc;

import com.krushikranti.subscription.dto.SubscriptionStatusResponse;
import com.krushikranti.subscription.service.SubscriptionService;
import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.server.service.GrpcService;

/**
 * gRPC Service for subscription operations.
 * Exposed to other microservices for subscription status checks.
 */
@GrpcService
@RequiredArgsConstructor
@Slf4j
public class SubscriptionGrpcService extends SubscriptionServiceGrpc.SubscriptionServiceImplBase {

    private final SubscriptionService subscriptionService;

    @Override
    public void checkSubscription(CheckSubscriptionRequest request, 
            StreamObserver<CheckSubscriptionResponse> responseObserver) {
        
        try {
            Long userId = Long.parseLong(request.getUserId());
            boolean isSubscribed = subscriptionService.isSubscribed(userId);
            
            CheckSubscriptionResponse response = CheckSubscriptionResponse.newBuilder()
                    .setIsSubscribed(isSubscribed)
                    .setSubscriptionStatus(isSubscribed ? "ACTIVE" : "NONE")
                    .setMessage(isSubscribed ? "User is subscribed" : "User is not subscribed")
                    .build();
            
            responseObserver.onNext(response);
            responseObserver.onCompleted();
            
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", request.getUserId());
            responseObserver.onError(io.grpc.Status.INVALID_ARGUMENT
                    .withDescription("Invalid user ID format")
                    .asRuntimeException());
        } catch (Exception e) {
            log.error("Error checking subscription: ", e);
            responseObserver.onError(io.grpc.Status.INTERNAL
                    .withDescription("Internal error")
                    .asRuntimeException());
        }
    }

    @Override
    public void getSubscriptionStatus(GetSubscriptionStatusRequest request,
            StreamObserver<com.krushikranti.subscription.grpc.SubscriptionStatusResponse> responseObserver) {
        
        try {
            Long userId = Long.parseLong(request.getUserId());
            SubscriptionStatusResponse status = subscriptionService.getSubscriptionStatus(userId);
            
            com.krushikranti.subscription.grpc.SubscriptionStatusResponse.Builder responseBuilder = 
                    com.krushikranti.subscription.grpc.SubscriptionStatusResponse.newBuilder()
                    .setUserId(userId)
                    .setIsSubscribed(status.isSubscribed())
                    .setSubscriptionStatus(status.getSubscriptionStatus() != null ? status.getSubscriptionStatus() : "")
                    .setPaymentStatus(status.getPaymentStatus() != null ? status.getPaymentStatus() : "")
                    .setDaysRemaining(status.getDaysRemaining() != null ? status.getDaysRemaining() : 0)
                    .setAmount(status.getSubscriptionAmount() != null ? status.getSubscriptionAmount().toString() : "999")
                    .setCurrency(status.getCurrency() != null ? status.getCurrency() : "INR")
                    .setMessage(status.getMessage() != null ? status.getMessage() : "");

            if (status.getSubscriptionId() != null) {
                responseBuilder.setSubscriptionId(status.getSubscriptionId());
            }
            if (status.getFarmerId() != null) {
                responseBuilder.setFarmerId(status.getFarmerId());
            }
            if (status.getSubscriptionStartDate() != null) {
                responseBuilder.setSubscriptionStartDate(status.getSubscriptionStartDate().toString());
            }
            if (status.getSubscriptionEndDate() != null) {
                responseBuilder.setSubscriptionEndDate(status.getSubscriptionEndDate().toString());
            }
            
            responseObserver.onNext(responseBuilder.build());
            responseObserver.onCompleted();
            
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", request.getUserId());
            responseObserver.onError(io.grpc.Status.INVALID_ARGUMENT
                    .withDescription("Invalid user ID format")
                    .asRuntimeException());
        } catch (Exception e) {
            log.error("Error getting subscription status: ", e);
            responseObserver.onError(io.grpc.Status.INTERNAL
                    .withDescription("Internal error")
                    .asRuntimeException());
        }
    }
}

