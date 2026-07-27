package com.nayasantha.api.common;

/** Domain exception carrying a stable {@link ErrorCode} and a developer detail. */
public class ApiException extends RuntimeException {

    private final ErrorCode errorCode;
    private final String userMessage;   // optional override of the code's canned message

    public ApiException(ErrorCode errorCode, String developerMessage) {
        this(errorCode, developerMessage, null);
    }

    public ApiException(ErrorCode errorCode, String developerMessage, String userMessage) {
        super(developerMessage);
        this.errorCode = errorCode;
        this.userMessage = userMessage;
    }

    public ErrorCode getErrorCode() { return errorCode; }

    /** A safe-to-show message overriding {@link ErrorCode#userMessage()}, or null. */
    public String getUserMessage() { return userMessage; }

    public static ApiException notFound(String what) {
        return new ApiException(ErrorCode.NOT_FOUND, what + " not found");
    }

    public static ApiException forbidden(String detail) {
        return new ApiException(ErrorCode.FORBIDDEN, detail);
    }

    /** A 400 whose message is safe to show the user verbatim. */
    public static ApiException userError(String message) {
        return new ApiException(ErrorCode.VALIDATION_ERROR, message, message);
    }
}
