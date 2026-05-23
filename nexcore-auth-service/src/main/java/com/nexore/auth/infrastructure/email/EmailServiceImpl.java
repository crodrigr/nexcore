package com.nexore.auth.infrastructure.email;

import com.nexore.auth.domain.exception.EmailSendingException;
import com.nexore.auth.domain.model.OtpCode;
import com.nexore.auth.domain.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailServiceImpl implements EmailService {
    
    private final JavaMailSender mailSender;
    
    @Value("${nexcore.auth.email.from}")
    private String fromEmail;
    
    @Value("${nexcore.auth.email.from-name}")
    private String fromName;
    
    @Value("${nexcore.auth.otp.expiry-minutes}")
    private int otpExpiryMinutes;
    
    @Value("${nexcore.auth.password-reset.expiry-minutes}")
    private int passwordResetExpiryMinutes;
    
    @Value("${app.frontend.base-url}")
    private String frontendBaseUrl;
    
    @Override
    public void sendOtpEmail(String toEmail, String username, OtpCode otpCode) {
        String subject = "Your OTP Code - NexCore Platform";
        String htmlContent = buildOtpEmailHtml(username, otpCode.getPlainCode());
        
        try {
            sendHtmlEmail(toEmail, subject, htmlContent);
            log.info("OTP email sent successfully to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {}", toEmail, e);
            throw new EmailSendingException("Failed to send OTP email", e);
        }
    }
    
    @Override
    public void sendPasswordResetEmail(String toEmail, String username, String resetToken) {
        String subject = "Password Reset Request - NexCore Platform";
        String resetUrl = buildPasswordResetUrl(resetToken);
        String htmlContent = buildPasswordResetEmailHtml(username, resetUrl);
        
        try {
            sendHtmlEmail(toEmail, subject, htmlContent);
            log.info("Password reset email sent successfully to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send password reset email to {}", toEmail, e);
            throw new EmailSendingException("Failed to send password reset email", e);
        }
    }
    
    @Override
    public void sendPasswordChangedEmail(String toEmail, String username) {
        String subject = "Password Changed - NexCore Platform";
        String htmlContent = buildPasswordChangedEmailHtml(username);
        
        try {
            sendHtmlEmail(toEmail, subject, htmlContent);
            log.info("Password changed email sent successfully to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send password changed email to {}", toEmail, e);
            // No lanzar excepción, este es un email de notificación
        }
    }
    
    private void sendHtmlEmail(String to, String subject, String htmlContent) throws MessagingException, java.io.UnsupportedEncodingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        
        helper.setFrom(fromEmail, fromName);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(htmlContent, true);
        
        mailSender.send(message);
    }
    
    private String buildOtpEmailHtml(String username, String otpCode) {
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .otp-code { 
                        font-size: 32px; 
                        font-weight: bold; 
                        color: #2563eb; 
                        letter-spacing: 5px;
                        padding: 20px;
                        background-color: #f3f4f6;
                        border-radius: 8px;
                        text-align: center;
                        margin: 20px 0;
                    }
                    .footer { font-size: 12px; color: #6b7280; margin-top: 30px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>Hello %s,</h2>
                    <p>You have requested to log in to the NexCore Platform.</p>
                    <p>Please use the following One-Time Password (OTP) to complete your login:</p>
                    <div class="otp-code">%s</div>
                    <p>This code will expire in <strong>%d minutes</strong>.</p>
                    <p>If you did not request this code, please ignore this email.</p>
                    <div class="footer">
                        <p>This is an automated message from NexCore Platform. Please do not reply to this email.</p>
                    </div>
                </div>
            </body>
            </html>
            """, username, otpCode, otpExpiryMinutes);
    }
    
    private String buildPasswordResetEmailHtml(String username, String resetUrl) {
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .button {
                        display: inline-block;
                        padding: 12px 24px;
                        background-color: #2563eb;
                        color: white;
                        text-decoration: none;
                        border-radius: 6px;
                        margin: 20px 0;
                    }
                    .footer { font-size: 12px; color: #6b7280; margin-top: 30px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>Hello %s,</h2>
                    <p>You have requested to reset your password for the NexCore Platform.</p>
                    <p>Click the button below to reset your password:</p>
                    <a href="%s" class="button">Reset Password</a>
                    <p>Or copy and paste this link in your browser:</p>
                    <p><a href="%s">%s</a></p>
                    <p>This link will expire in <strong>%d minutes</strong>.</p>
                    <p>If you did not request a password reset, please ignore this email.</p>
                    <div class="footer">
                        <p>This is an automated message from NexCore Platform. Please do not reply to this email.</p>
                    </div>
                </div>
            </body>
            </html>
            """, username, resetUrl, resetUrl, resetUrl, passwordResetExpiryMinutes);
    }
    
    private String buildPasswordChangedEmailHtml(String username) {
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .footer { font-size: 12px; color: #6b7280; margin-top: 30px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>Hello %s,</h2>
                    <p>Your password for the NexCore Platform has been successfully changed.</p>
                    <p>If you did not make this change, please contact your administrator immediately.</p>
                    <div class="footer">
                        <p>This is an automated message from NexCore Platform. Please do not reply to this email.</p>
                    </div>
                </div>
            </body>
            </html>
            """, username);
    }
    
    private String buildPasswordResetUrl(String token) {
        // Use configured frontend base URL from application.yml
        String base = frontendBaseUrl != null && !frontendBaseUrl.isBlank() ? frontendBaseUrl : "https://app.nexcore.com";
        // Ensure no trailing slash
        if (base.endsWith("/")) base = base.substring(0, base.length() - 1);
        return String.format("%s/reset-password?token=%s", base, token);
    }
}
