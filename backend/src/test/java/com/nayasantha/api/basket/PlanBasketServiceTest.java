package com.nayasantha.api.basket;

import com.nayasantha.api.plan.*;
import org.junit.jupiter.api.Test;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class PlanBasketServiceTest {
    @Test void retryDoesNotAddPlanQuantitiesTwice() {
        WeeklyPlanRepository plans=mock(WeeklyPlanRepository.class);
        WeeklyPlanItemRepository items=mock(WeeklyPlanItemRepository.class);
        BasketService baskets=mock(BasketService.class);
        PlanBasketService service=new PlanBasketService(plans,items,baskets);
        UUID user=UUID.randomUUID(),id=UUID.randomUUID(),product=UUID.randomUUID();
        WeeklyPlan plan=new WeeklyPlan();plan.setUserId(user);
        when(plans.lockById(id)).thenReturn(Optional.of(plan));
        WeeklyPlanItem line=new WeeklyPlanItem();line.setProductId(product);line.setQuantity(3);
        when(items.findByPlanId(id)).thenReturn(List.of(line));
        service.add(user,id); service.add(user,id);
        verify(baskets,times(1)).addItem(user,product,3);
        assertEquals(WeeklyPlan.Status.APPROVED,plan.getStatus());
    }
}
