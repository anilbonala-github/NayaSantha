package com.nayasantha.api.common;

import org.springframework.http.HttpStatus;

/**
 * Stable machine-readable error codes returned to clients (Vol2 §5.1).
 * The {@code userMessage} is safe to show; {@code developerMessage} carries detail.
 */
public enum ErrorCode {
    VALIDATION_ERROR(HttpStatus.BAD_REQUEST, "Please check the highlighted fields and try again."),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "Please sign in to continue."),
    FORBIDDEN(HttpStatus.FORBIDDEN, "You don't have access to this resource."),
    NOT_FOUND(HttpStatus.NOT_FOUND, "We couldn't find what you were looking for."),
    OTP_INVALID(HttpStatus.BAD_REQUEST, "That code is incorrect or has expired. Request a new one."),
    OTP_RATE_LIMITED(HttpStatus.TOO_MANY_REQUESTS, "Too many attempts. Please wait a moment and try again."),
    TOKEN_INVALID(HttpStatus.UNAUTHORIZED, "Your session has expired. Please sign in again."),
    VERSION_CONFLICT(HttpStatus.CONFLICT, "This changed on another device. Refresh and try again."),
    NOT_SERVICEABLE(HttpStatus.UNPROCESSABLE_ENTITY, "We don't deliver to this area yet."),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "Something went wrong on our side. Please try again.");

    private final HttpStatus status;
    private final String userMessage;

    ErrorCode(HttpStatus status, String userMessage) {
        this.status = status;
        this.userMessage = userMessage;
    }

    public HttpStatus status() { return status; }
    public String userMessage() { return userMessage; }
}
