package com.nexore.core.module.tenant.application.exception;

import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;

@Getter
@Builder
public class ApiError {
    private final String code;
    private final String message;
    private final int status;
    private final OffsetDateTime timestamp;
}
