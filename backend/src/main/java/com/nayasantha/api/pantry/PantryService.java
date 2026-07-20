package com.nayasantha.api.pantry;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.pantry.PantryDtos.*;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/** Household pantry with backend-computed low-stock and expiry status (Vol2 §6.4). */
@Service
public class PantryService {

    private static final int EXPIRING_WINDOW_DAYS = 3;

    private final PantryItemRepository pantry;

    public PantryService(PantryItemRepository pantry) {
        this.pantry = pantry;
    }

    @Transactional(readOnly = true)
    public List<PantryItemDto> list(UUID userId) {
        LocalDate today = LocalDate.now();
        return pantry.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(i -> toDto(i, today)).toList();
    }

    /** Products the household already has in sufficient quantity — the planner
     *  skips these so it doesn't buy them twice (Vol1 §4.1). */
    @Transactional(readOnly = true)
    public Set<UUID> wellStockedProductIds(UUID userId) {
        return pantry.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(i -> i.getProductId() != null)
                .filter(i -> i.getQuantity().compareTo(i.getLowStockThreshold()) > 0)
                .map(PantryItem::getProductId)
                .collect(Collectors.toSet());
    }

    @Transactional
    public PantryItemDto add(UUID userId, UpsertPantryItemRequest req) {
        PantryItem item = new PantryItem();
        item.setUserId(userId);
        apply(item, req);
        return toDto(pantry.save(item), LocalDate.now());
    }

    @Transactional
    public PantryItemDto update(UUID userId, UUID id, UpsertPantryItemRequest req) {
        PantryItem item = owned(userId, id);
        if (req.version() != null && !req.version().equals(item.getVersion())) {
            throw new ObjectOptimisticLockingFailureException(
                    "expected version " + item.getVersion() + " but received " + req.version(), null);
        }
        apply(item, req);
        return toDto(pantry.save(item), LocalDate.now());
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        pantry.delete(owned(userId, id));
    }

    // --- helpers -----------------------------------------------------------
    private PantryItem owned(UUID userId, UUID id) {
        PantryItem i = pantry.findById(id).orElseThrow(() -> ApiException.notFound("Pantry item"));
        if (!i.getUserId().equals(userId)) throw ApiException.forbidden("Not your pantry item");
        return i;
    }

    private void apply(PantryItem item, UpsertPantryItemRequest req) {
        item.setProductId(req.productId());
        item.setName(req.name());
        if (req.quantity() != null) item.setQuantity(req.quantity());
        item.setUnit(req.unit());
        if (req.lowStockThreshold() != null) item.setLowStockThreshold(req.lowStockThreshold());
        item.setPurchaseDate(req.purchaseDate());
        item.setExpiryDate(req.expiryDate());
    }

    private PantryItemDto toDto(PantryItem i, LocalDate today) {
        String stock = i.getQuantity().compareTo(i.getLowStockThreshold()) <= 0 ? "LOW" : "OK";
        String expiryStatus = "OK";
        Integer daysToExpiry = null;
        if (i.getExpiryDate() != null) {
            long days = ChronoUnit.DAYS.between(today, i.getExpiryDate());
            daysToExpiry = (int) days;
            if (days < 0) expiryStatus = "EXPIRED";
            else if (days <= EXPIRING_WINDOW_DAYS) expiryStatus = "EXPIRING";
        }
        return new PantryItemDto(i.getId(), i.getProductId(), i.getName(), i.getQuantity(),
                i.getUnit(), i.getLowStockThreshold(), i.getPurchaseDate(), i.getExpiryDate(),
                i.getSource().name(), stock, expiryStatus, daysToExpiry, i.getVersion());
    }
}
