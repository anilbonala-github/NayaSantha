package com.nayasantha.api.wallet;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import com.nayasantha.api.wallet.WalletDtos.*;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Wallet reads for the signed-in customer (Vol2 §6, wallet module). */
@RestController
@RequestMapping("/api/v1/wallet")
public class WalletController {

    private final WalletService wallet;

    public WalletController(WalletService wallet) {
        this.wallet = wallet;
    }

    /** Balance + recent transactions. */
    @GetMapping
    public ApiResponse<WalletDto> get() {
        var id = CurrentUser.id();
        return ApiResponse.of(new WalletDto(wallet.balance(id), wallet.list(id, 0, 10)));
    }

    @GetMapping("/transactions")
    public ApiResponse<List<TransactionDto>> transactions(@RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "30") int size) {
        return ApiResponse.of(wallet.list(CurrentUser.id(), page, size));
    }
}
