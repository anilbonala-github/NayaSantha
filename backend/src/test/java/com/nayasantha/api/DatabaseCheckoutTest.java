package com.nayasantha.api;

import com.nayasantha.api.basket.BasketService;
import com.nayasantha.api.order.CheckoutService;
import com.nayasantha.api.common.ApiException;
import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
@SpringBootTest(properties = {"nayasantha.scheduler.enabled=false", "nayasantha.push.fcm.enabled=false",
        "nayasantha.otp.dev-mode=true", "nayasantha.otp.dev-code=000000", "nayasantha.payments.razorpay.enabled=false", "nayasantha.gemini.api-key="})
class DatabaseCheckoutTest {
    static final EmbeddedPostgres POSTGRES;
    static {
        try {
            POSTGRES = EmbeddedPostgres.builder().setPort(0).start();
            // Reproduce the deployed V20 schema, then let application startup upgrade it.
            Flyway.configure().dataSource(POSTGRES.getPostgresDatabase()).target("20").load().migrate();
        } catch (Exception e) { throw new ExceptionInInitializerError(e); }
    }
    @DynamicPropertySource static void database(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", () -> POSTGRES.getJdbcUrl("postgres", "postgres"));
        r.add("spring.datasource.username", () -> "postgres");
        r.add("spring.datasource.password", () -> "postgres");
    }
    @Autowired JdbcTemplate db;
    @Autowired BasketService baskets;
    @Autowired CheckoutService checkout;

    @Autowired org.springframework.test.web.servlet.MockMvc http;
    @Autowired com.fasterxml.jackson.databind.ObjectMapper json;
    private com.fasterxml.jackson.databind.JsonNode request(String method, String path, String body, String token) throws Exception {
        var req = org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request(org.springframework.http.HttpMethod.valueOf(method), path)
                .contentType("application/json").content(body);
        if (token != null) req.header("Authorization", "Bearer " + token);
        var result = http.perform(req).andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().is2xxSuccessful()).andReturn();
        return json.readTree(result.getResponse().getContentAsString()).path("data");
    }
    @Test void authenticatedHouseholdToOrderFlowPersistsAcrossRequests() throws Exception {
        request("POST", "/api/v1/auth/otp/request", "{\"mobile\":\"9000000001\"}", null);
        var login = request("POST", "/api/v1/auth/otp/verify", "{\"mobile\":\"9000000001\",\"code\":\"000000\"}", null);
        String token = login.path("accessToken").asText();
        assertFalse(token.isBlank());
        request("PATCH", "/api/v1/profile", "{\"name\":\"Test household\"}", token);
        var member = request("POST", "/api/v1/household-members", "{\"name\":\"Adult\",\"age\":30,\"dietaryType\":\"VEG\"}", token);
        request("PATCH", "/api/v1/household-members/" + member.path("id").asText(), "{\"name\":\"Updated adult\",\"clearAge\":true}", token);
        request("PATCH", "/api/v1/households/current", "{\"weeklyBudget\":1500}", token);
        request("POST", "/api/v1/addresses", "{\"line1\":\"Test delivery address\",\"city\":\"Hyderabad\",\"pincode\":\"500081\",\"isDefault\":true}", token);
        assertEquals("COMPLETE", request("POST", "/api/v1/profile/complete", "", token).path("profileCompletionStatus").asText());
        var household = request("GET", "/api/v1/households/current", "", token);
        assertEquals(1, household.path("members").size());
        assertEquals("Updated adult", household.path("members").get(0).path("name").asText());
        assertTrue(household.path("members").get(0).path("age").isMissingNode());
        request("POST", "/api/v1/baskets/current/items", "{\"productId\":\"" + product + "\",\"quantity\":2}", token);
        var review = request("GET", "/api/v1/baskets/current/checkout-preview", "", token);
        String body = json.writeValueAsString(java.util.Map.of("basketId", review.path("basketId").asText(), "quoteToken", review.path("quoteToken").asText()));
        var order = request("POST", "/api/v1/baskets/current/checkout", body, token);
        var retry = request("POST", "/api/v1/baskets/current/checkout", body, token);
        assertEquals(order.path("id").asText(), retry.path("id").asText());
        var saved = request("GET", "/api/v1/orders/" + order.path("id").asText(), "", token);
        assertEquals("FIXED_WEEKLY", saved.path("pricingMode").asText());
        assertEquals(review.path("total").decimalValue(), saved.path("amountPayable").decimalValue());
    }

    UUID user, product;
    @BeforeEach void seed() {
        user = UUID.randomUUID();
        db.update("insert into users(id,mobile,name) values (?,?,?)", user, user.toString().substring(0,18), "Integration household");
        db.update("insert into addresses(user_id,line1,city,pincode,is_serviceable,is_default) values (?, 'Test address', 'Hyderabad', '500081', true, true)", user);
        product = db.queryForObject("select product_id from product_prices where active=true and effective_from <= now() and (effective_to is null or effective_to > now()) limit 1", UUID.class);
    }
    @Test void upgradesV20AndValidatesEntireHibernateSchema() {
        assertEquals(22, db.queryForObject("select count(*) from flyway_schema_history where success=true and version is not null", Integer.class));
        assertEquals(1, db.queryForObject("select count(*) from price_calendars where zone='HYD_PILOT'", Integer.class));
    }
    @Test void checkoutPersistsAndRetryReturnsSameOrder() {
        baskets.addItem(user, product, 2);
        var review = checkout.preview(user);
        var order = checkout.checkout(user, review.basketId(), review.quoteToken());
        var retry = checkout.checkout(user, review.basketId(), review.quoteToken());
        assertEquals(order.id(), retry.id());
        assertEquals(0, review.total().compareTo(order.amountPayable()));
        assertEquals("FIXED_WEEKLY", order.pricingMode());
        assertEquals(1, db.queryForObject("select count(*) from orders where basket_id=?", Integer.class, review.basketId()));
        assertEquals("CHECKED_OUT", db.queryForObject("select status from baskets where id=?", String.class, review.basketId()));
        assertNotEquals(review.basketId(), baskets.getCurrent(user).id());
    }
    @Test void staleQuantityDoesNotPartiallyCreateOrder() {
        baskets.addItem(user, product, 1);
        var review = checkout.preview(user);
        baskets.addItem(user, product, 1);
        assertThrows(ApiException.class, () -> checkout.checkout(user, review.basketId(), review.quoteToken()));
        assertEquals(0, db.queryForObject("select count(*) from orders where user_id=?", Integer.class, user));
        assertEquals("ACTIVE", db.queryForObject("select status from baskets where id=?", String.class, review.basketId()));
    }
}
