package com.nexore.core.module.tenant.application.service;

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
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String fromEmail;

    @Value("${app.mail.from-name}")
    private String fromName;

    @Value("${app.mail.frontend-url}")
    private String frontendUrl;

    public void sendInvitation(String toEmail, String rawToken, java.util.UUID tenantId) {
        String link = frontendUrl + "/auth/accept-invitation?token=" + rawToken + "&tenantId=" + tenantId;
        String subject = "You have been invited to NexCore";
        String html = buildInvitationHtml(link);
        try {
            sendHtmlEmail(toEmail, subject, html);
            log.info("Invitation email sent to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send invitation email to {}: {}", toEmail, e.getMessage());
            throw new IllegalStateException("Failed to send invitation email to " + toEmail, e);
        }
    }

    private void sendHtmlEmail(String to, String subject, String html)
            throws MessagingException, java.io.UnsupportedEncodingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setFrom(fromEmail, fromName);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(html, true);
        mailSender.send(message);
    }

    private String buildInvitationHtml(String link) {
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .button {
                        display: inline-block;
                        padding: 12px 28px;
                        background-color: #1976d2;
                        color: white;
                        text-decoration: none;
                        border-radius: 8px;
                        font-weight: 600;
                        margin: 20px 0;
                    }
                    .footer { font-size: 12px; color: #6b7280; margin-top: 30px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>You've been invited to NexCore</h2>
                    <p>Hello,</p>
                    <p>You have been invited to join the NexCore Platform. Click the button below to accept your invitation and set up your account.</p>
                    <a href="%s" class="button">Accept Invitation</a>
                    <p>Or copy and paste this link in your browser:</p>
                    <p><a href="%s">%s</a></p>
                    <p>This link expires in <strong>72 hours</strong>.</p>
                    <p>If you did not expect this invitation, you can ignore this email.</p>
                    <div class="footer">
                        <p>This is an automated message from NexCore Platform. Please do not reply to this email.</p>
                    </div>
                </div>
            </body>
            </html>
            """, link, link, link);
    }
}
