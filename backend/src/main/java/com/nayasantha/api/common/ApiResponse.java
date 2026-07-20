package com.nayasantha.api.common;

import org.slf4j.MDC;

import java.util.Map;

/**
 * Success envelope (Vol2 §5.1): {@code { "data": ..., "meta": { "traceId": ... } }}.
 */
public record ApiResponse<T>(T data, Map<String, Object> meta) {

    public static <T> ApiResponse<T> of(T data) {
        String traceId = MDC.get("traceId");
        return new ApiResponse<>(data, Map.of("traceId", traceId == null ? "" : traceId));
    }
}
