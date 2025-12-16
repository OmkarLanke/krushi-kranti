package com.krushikranti.auth.dto;

import lombok.Data;

@Data
public class LoginRequest {
    // Email/Password login fields (optional - use together)
    private String email;
    private String password;

    // Phone/OTP login fields (optional - use together)
    private String phoneNumber;
    private String otp;

    // Helper methods to determine login method
    public boolean isEmailLogin() {
        return email != null && !email.isEmpty() && password != null && !password.isEmpty() 
               && (phoneNumber == null || phoneNumber.isEmpty()) && (otp == null || otp.isEmpty());
    }

    public boolean isPhoneLogin() {
        return phoneNumber != null && !phoneNumber.isEmpty() && otp != null && !otp.isEmpty()
               && (email == null || email.isEmpty()) && (password == null || password.isEmpty());
    }
}

