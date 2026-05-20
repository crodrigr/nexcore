package com.nexore.core.module.tenant.infrastructure.web;

import com.nexore.core.module.tenant.application.exception.ApiError;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.OffsetDateTime;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiError> handleBusinessException(BusinessException ex) {
        ApiError error = ApiError.builder()
                .code(ex.getErrorCode())
                .message(ex.getMessage())
                .status(ex.getHttpStatus().value())
                .timestamp(OffsetDateTime.now())
                .build();
        return ResponseEntity.status(ex.getHttpStatus()).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidationException(MethodArgumentNotValidException ex) {
        String detail = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .collect(Collectors.joining("; "));
        ApiError error = ApiError.builder()
                .code("NXC-VALIDATION-0001")
                .message("Invalid input data: " + detail)
                .status(422)
                .timestamp(OffsetDateTime.now())
                .build();
        return ResponseEntity.unprocessableEntity().body(error);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGenericException(Exception ex) {
        ApiError error = ApiError.builder()
                .code("NXC-INTERNAL-0001")
                .message("An unexpected internal server error occurred.")
                .status(500)
                .timestamp(OffsetDateTime.now())
                .build();
        return ResponseEntity.internalServerError().body(error);
    }
}
