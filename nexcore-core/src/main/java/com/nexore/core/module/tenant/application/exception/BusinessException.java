package com.nexore.core.module.tenant.application.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.UUID;

@Getter
public class BusinessException extends RuntimeException {

    private final String errorCode;
    private final HttpStatus httpStatus;

    public BusinessException(String errorCode, String message, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    // ---- Tenant errors ----

    public static BusinessException tenantSlugAlreadyExists(String slug) {
        return new BusinessException("NXC-TEN-0001",
                "Slug '" + slug + "' already exists in an active tenant.", HttpStatus.CONFLICT);
    }

    public static BusinessException customDomainAlreadyInUse(String domain) {
        return new BusinessException("NXC-TEN-0002",
                "Custom domain '" + domain + "' is already in use by another tenant.", HttpStatus.CONFLICT);
    }

    public static BusinessException tenantNotFound() {
        return new BusinessException("NXC-TEN-0003", "Tenant not found.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException tenantAccessForbidden() {
        return new BusinessException("NXC-TEN-0004", "Access to this tenant is not allowed.", HttpStatus.FORBIDDEN);
    }

    public static BusinessException tenantVersionConflict() {
        return new BusinessException("NXC-TEN-0005", "Version conflict while updating tenant. Please reload and retry.", HttpStatus.CONFLICT);
    }

    public static BusinessException tenantAdminCannotChangePlan() {
        return new BusinessException("NXC-TEN-0006", "TENANT_ADMIN is not allowed to change the tenant plan.", HttpStatus.FORBIDDEN);
    }

    public static BusinessException tenantInvalidSlug(String slug) {
        return new BusinessException("NXC-TEN-0010",
                "Slug '" + slug + "' contains invalid characters. Use only lowercase letters, digits and hyphens.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    // ---- User errors ----

    public static BusinessException userEmailAlreadyExists(String email) {
        return new BusinessException("NXC-USR-0001",
                "Email '" + email + "' already exists in this tenant.", HttpStatus.CONFLICT);
    }

    public static BusinessException invitationPendingForEmail(String email) {
        return new BusinessException("NXC-USR-0002",
                "A pending invitation already exists for email '" + email + "'.", HttpStatus.CONFLICT);
    }

    public static BusinessException usernameAlreadyExists(String username) {
        return new BusinessException("NXC-USR-0003",
                "Username '" + username + "' already exists in this tenant.", HttpStatus.CONFLICT);
    }

    public static BusinessException userQuotaReached() {
        return new BusinessException("NXC-USR-0010",
                "User quota for this tenant's plan has been reached.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException roleDoesNotBelongToTenant() {
        return new BusinessException("NXC-USR-0011",
                "One or more roles do not belong to this tenant.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException invitationInvalidOrExpired() {
        return new BusinessException("NXC-USR-0020",
                "Invitation token is invalid or has expired.", HttpStatus.BAD_REQUEST);
    }

    public static BusinessException invitationAlreadyUsed() {
        return new BusinessException("NXC-USR-0021",
                "Invitation token has already been used.", HttpStatus.BAD_REQUEST);
    }

    public static BusinessException passwordPolicyViolation(String detail) {
        return new BusinessException("NXC-USR-0030",
                "Password does not meet tenant policy requirements: " + detail, HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException emailCannotBeChanged() {
        return new BusinessException("NXC-USR-0040",
                "Email address cannot be changed after the user is created.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException userVersionConflict() {
        return new BusinessException("NXC-USR-0041",
                "Version conflict while updating user. Please reload and retry.", HttpStatus.CONFLICT);
    }

    public static BusinessException cannotSuspendSelf() {
        return new BusinessException("NXC-USR-0050",
                "A user cannot suspend themselves.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException cannotSuspendLastTenantAdmin() {
        return new BusinessException("NXC-USR-0051",
                "Cannot suspend the last active TENANT_ADMIN of this tenant.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException cannotDeleteLastTenantAdmin() {
        return new BusinessException("NXC-USR-0060",
                "Cannot delete the last active TENANT_ADMIN of this tenant.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException cannotDeleteSelf() {
        return new BusinessException("NXC-USR-0061",
                "A user cannot delete themselves.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException userNotFound() {
        return new BusinessException("NXC-USR-0003", "User not found.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException invitationAlreadyAccepted() {
        return new BusinessException("NXC-USR-0070",
                "Invitation has already been accepted.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    // ---- Role errors ----

    public static BusinessException roleNameDuplicated(String name) {
        return new BusinessException("NXC-ROL-0001",
                "Role name '" + name + "' already exists in this tenant.", HttpStatus.CONFLICT);
    }

    public static BusinessException roleNameReserved(String name) {
        return new BusinessException("NXC-ROL-0002",
                "Role name '" + name + "' is reserved for system roles.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException cannotRenameSystemRole() {
        return new BusinessException("NXC-ROL-0010",
                "System roles cannot be renamed.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException cannotDeleteSystemRole() {
        return new BusinessException("NXC-ROL-0020",
                "System roles cannot be deleted.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException roleHasActiveUsers(long count) {
        return new BusinessException("NXC-ROL-0021",
                "Role has " + count + " active user(s) assigned and cannot be deleted.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException roleNotFound() {
        return new BusinessException("NXC-ROL-0001", "Role not found.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException assignRoleDoesNotBelongToTenant() {
        return new BusinessException("NXC-ROL-0030",
                "One or more roleIds do not belong to this tenant.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    public static BusinessException assignmentWouldRemoveLastTenantAdmin() {
        return new BusinessException("NXC-ROL-0031",
                "This operation would leave the tenant with no active TENANT_ADMIN.", HttpStatus.UNPROCESSABLE_ENTITY);
    }

    // ---- Menu / profile errors ----

    public static BusinessException menuUserNotFound() {
        return new BusinessException("NXC-MNU-0001",
                "User not found or not active in this tenant.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException menuTenantNotActive() {
        return new BusinessException("NXC-MNU-0002",
                "Tenant not found or not in an active state.", HttpStatus.FORBIDDEN);
    }

    public static BusinessException menuUserSuspended() {
        return new BusinessException("NXC-MNU-0003",
                "User account is suspended or blocked.", HttpStatus.FORBIDDEN);
    }

    // ---- Component / Element / Permission errors ----

    public static BusinessException componentNotFound() {
        return new BusinessException("NXC-CMP-0001",
                "Component not found in this tenant.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException elementNotFound() {
        return new BusinessException("NXC-ELM-0001",
                "Element not found in this component.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException permissionRoleNotFound() {
        return new BusinessException("NXC-PRM-0001",
                "Role not found in this tenant.", HttpStatus.NOT_FOUND);
    }

    public static BusinessException permissionInvalidComponentIds(List<UUID> invalidIds) {
        return new BusinessException("NXC-PRM-0002",
                "One or more componentIds do not belong to this tenant: " + invalidIds,
                HttpStatus.UNPROCESSABLE_ENTITY);
    }
}
