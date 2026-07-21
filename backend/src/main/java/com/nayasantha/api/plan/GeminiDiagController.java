package com.nayasantha.api.plan;

import com.nayasantha.api.common.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Temporary public diagnostic for the Gemini integration. Reports whether the
 * key is loaded and the exact status/error from a minimal call. Never returns
 * the key. Remove once Gemini is confirmed working.
 */
@RestController
@RequestMapping("/api/v1")
public class GeminiDiagController {

    private final GeminiPlanner planner;

    public GeminiDiagController(GeminiPlanner planner) {
        this.planner = planner;
    }

    @GetMapping("/gemini-check")
    public ApiResponse<Map<String, Object>> check(
            @RequestParam(required = false) String model) {
        return ApiResponse.of(planner.selfTest(model));
    }
}
