package com.krushikranti.kyc.grpc;

import com.krushikranti.kyc.dto.KycStatusResponse;
import com.krushikranti.kyc.service.KycService;
import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.server.service.GrpcService;

/**
 * gRPC Service for KYC verification.
 * Allows other microservices to check KYC status.
 */
@GrpcService
@RequiredArgsConstructor
@Slf4j
public class KycGrpcService extends KycServiceGrpc.KycServiceImplBase {

    private final KycService kycService;

    @Override
    public void checkKyc(CheckKycRequest request, StreamObserver<CheckKycResponse> responseObserver) {
        log.info("gRPC CheckKyc called for userId: {}", request.getUserId());
        
        try {
            Long userId = Long.parseLong(request.getUserId());
            KycStatusResponse status = kycService.getKycStatus(userId);
            
            CheckKycResponse response = CheckKycResponse.newBuilder()
                    .setIsComplete(Boolean.TRUE.equals(status.getAadhaarVerified()) &&
                                  Boolean.TRUE.equals(status.getPanVerified()) &&
                                  Boolean.TRUE.equals(status.getBankVerified()))
                    .setAadhaarVerified(Boolean.TRUE.equals(status.getAadhaarVerified()))
                    .setPanVerified(Boolean.TRUE.equals(status.getPanVerified()))
                    .setBankVerified(Boolean.TRUE.equals(status.getBankVerified()))
                    .setKycStatus(status.getKycStatus() != null ? status.getKycStatus().name() : "PENDING")
                    .build();
            
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (Exception e) {
            log.error("Error in gRPC CheckKyc", e);
            responseObserver.onError(io.grpc.Status.INTERNAL
                    .withDescription(e.getMessage())
                    .asRuntimeException());
        }
    }

    @Override
    public void getKycStatus(GetKycStatusRequest request, StreamObserver<com.krushikranti.kyc.grpc.KycStatusResponse> responseObserver) {
        log.info("gRPC GetKycStatus called for userId: {}", request.getUserId());
        
        try {
            Long userId = Long.parseLong(request.getUserId());
            KycStatusResponse status = kycService.getKycStatus(userId);
            
            com.krushikranti.kyc.grpc.KycStatusResponse.Builder builder = 
                    com.krushikranti.kyc.grpc.KycStatusResponse.newBuilder()
                    .setUserId(String.valueOf(status.getUserId()))
                    .setKycStatus(status.getKycStatus() != null ? status.getKycStatus().name() : "PENDING")
                    .setAadhaarVerified(Boolean.TRUE.equals(status.getAadhaarVerified()))
                    .setPanVerified(Boolean.TRUE.equals(status.getPanVerified()))
                    .setBankVerified(Boolean.TRUE.equals(status.getBankVerified()));
            
            // Add optional fields if present
            if (status.getAadhaarName() != null) {
                builder.setAadhaarName(status.getAadhaarName());
            }
            if (status.getAadhaarNumberMasked() != null) {
                builder.setAadhaarNumberMasked(status.getAadhaarNumberMasked());
            }
            if (status.getPanName() != null) {
                builder.setPanName(status.getPanName());
            }
            if (status.getPanNumberMasked() != null) {
                builder.setPanNumberMasked(status.getPanNumberMasked());
            }
            if (status.getBankAccountHolderName() != null) {
                builder.setBankAccountHolderName(status.getBankAccountHolderName());
            }
            if (status.getBankAccountMasked() != null) {
                builder.setBankAccountMasked(status.getBankAccountMasked());
            }
            if (status.getBankIfsc() != null) {
                builder.setBankIfsc(status.getBankIfsc());
            }
            if (status.getBankName() != null) {
                builder.setBankName(status.getBankName());
            }
            
            responseObserver.onNext(builder.build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            log.error("Error in gRPC GetKycStatus", e);
            responseObserver.onError(io.grpc.Status.INTERNAL
                    .withDescription(e.getMessage())
                    .asRuntimeException());
        }
    }
}

