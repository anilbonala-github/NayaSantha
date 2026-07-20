package com.nayasantha.api.common;

import org.slf4j.MDC;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.stream.Collectors;

/** Maps exceptions to the stable error envelope in Vol2 §5.1. */
@RestControllerAdvice
public class GlobalExceptionHandler {

    public record ApiError(String errorCode, String userMessage,
                           String developerMessage, String traceId) {}

    private ResponseEntity<ApiError> build(ErrorCode code, String developerMessage) {
        return ResponseEntity.status(code.status())
                .body(new ApiError(code.name(), code.userMessage(), developerMessage, MDC.get("traceId")));
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiError> handleApi(ApiException ex) {
        return build(ex.getErrorCode(), ex.getMessage());
    }

    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    public ResponseEntity<ApiError> handleConflict(ObjectOptimisticLockingFailureException ex) {
        return build(ErrorCode.VERSION_CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiError> handleDenied(AccessDeniedException ex) {
        return build(ErrorCode.FORBIDDEN, ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        String detail = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + messageOf(fe))
                .collect(Collectors.joining("; "));
        return build(ErrorCode.VALIDATION_ERROR, detail);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex) {
        return build(ErrorCode.INTERNAL_ERROR, ex.getClass().getSimpleName() + ": " + ex.getMessage());
    }

    private static String messageOf(FieldError fe) {
        return fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage();
    }
}
