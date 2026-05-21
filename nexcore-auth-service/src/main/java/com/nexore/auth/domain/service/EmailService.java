package com.nexore.auth.domain.service;

import com.nexore.auth.domain.model.OtpCode;

import java.util.UUID;

public interface EmailService {
    
    void sendOtpEmail(String toEmail, String username, OtpCode otpCode);
    
    void sendPasswordResetEmail(String toEmail, String username, String resetToken);
    
    void sendPasswordChangedEmail(String toEmail, String username);
}
