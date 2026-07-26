package com.nayasantha.api.settings;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.settings.SettingsDtos.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/** Ops settings (ADMIN-only via SecurityConfig /ops/** guard). */
@RestController
@RequestMapping("/api/v1/ops/settings")
public class SettingsController {

    private final SettingsService settings;

    public SettingsController(SettingsService settings) {
        this.settings = settings;
    }

    @GetMapping
    public ApiResponse<SettingsDto> get() {
        return ApiResponse.of(SettingsDto.from(settings.current()));
    }

    @PatchMapping
    public ApiResponse<SettingsDto> update(@Valid @RequestBody UpdateSettingsRequest body) {
        return ApiResponse.of(SettingsDto.from(settings.update(body)));
    }
}
