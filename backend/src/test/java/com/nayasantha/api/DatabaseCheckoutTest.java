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


    @Autowired com.nayasantha.api.security.JwtService jwt;
    @Autowired com.nayasantha.api.config.AppProperties props;
    private String tokenFor(String role) {
        db.update("update users set role=? where id=?",role,user);
        return jwt.issueAccessToken(user,"9000000010",role);
    }
    private void denied(String method,String path,String token,int expected) throws Exception {
        var req=org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request(org.springframework.http.HttpMethod.valueOf(method),path)
            .header("Authorization","Bearer "+token).contentType("application/json").content("{}");
        http.perform(req).andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().is(expected));
    }
    @Test void staffAccessUsesCurrentRoleAndNeverDummyOtp() throws Exception {
        String owner=tokenFor("OWNER");
        denied("GET","/api/v1/admin/products",owner,403);
        denied("POST","/api/v1/auth/admin/otp/request",owner,400);
        props.getOtp().setDevMode(false);
        try {
            denied("GET","/api/v1/admin/products",owner,403);
            owner=tokenFor("OWNER");
            request("GET","/api/v1/admin/products","",owner);
            String manager=tokenFor("CATALOGUE_MANAGER");
            request("GET","/api/v1/admin/products","",manager);
            denied("GET","/api/v1/admin/staff",manager,403);
            denied("GET","/api/v1/ops/settings",manager,403);
            db.update("update users set role='CUSTOMER' where id=?",user);
            denied("GET","/api/v1/admin/products",manager,403);
            db.update("update users set role='OWNER' where id=?",user);
            denied("GET","/api/v1/admin/products",manager,403);
            db.update("update users set status='SUSPENDED' where id=?",user);
            denied("GET","/api/v1/admin/products",owner,401);
        } finally {props.getOtp().setDevMode(true);}
    }

    @Test void ownerAssignsStaffAndRevokesPreviouslyIssuedTokens() throws Exception {
        props.getOtp().setDevMode(false);
        try {
            String owner=tokenFor("OWNER");
            var staff=request("PUT","/api/v1/admin/staff","{\"mobile\":\"9000000033\",\"role\":\"CATALOGUE_MANAGER\"}",owner);
            UUID id=UUID.fromString(staff.path("id").asText());
            long version=db.queryForObject("select role_version from users where id=?",Long.class,id);
            String token=jwt.issueAccessToken(id,"9000000033","CATALOGUE_MANAGER",version);
            request("GET","/api/v1/admin/products","",token);
            request("PUT","/api/v1/admin/staff","{\"mobile\":\"9000000033\",\"role\":\"CUSTOMER\"}",owner);
            denied("GET","/api/v1/admin/products",token,401);
            request("PUT","/api/v1/admin/staff","{\"mobile\":\"9000000033\",\"role\":\"CATALOGUE_MANAGER\"}",owner);
            denied("GET","/api/v1/admin/products",token,401);
        } finally {props.getOtp().setDevMode(true);}
    }
    @Test void adminProductDraftPublishArchiveAndPhotoFlow() throws Exception {
        props.getOtp().setDevMode(false);
        try {
            String token=tokenFor("OWNER");
            var category=request("POST","/api/v1/admin/categories",json.writeValueAsString(java.util.Map.of("name","Test vegetables","slug","test-"+UUID.randomUUID(),"sortOrder",2)),token);
            var body=new java.util.HashMap<String,Object>();
            body.put("sku","test-"+UUID.randomUUID());body.put("name","Test carrots");body.put("unit","500 g");body.put("categoryId",category.path("id").asText());
            body.put("publicationStatus","DRAFT");body.put("available",true);
            var draft=request("POST","/api/v1/admin/products",json.writeValueAsString(body),token);
            String id=draft.path("id").asText();
            denied("GET","/api/v1/products/"+id,token,404);
            var image=new java.awt.image.BufferedImage(2,2,java.awt.image.BufferedImage.TYPE_INT_RGB);
            var bytes=new java.io.ByteArrayOutputStream();javax.imageio.ImageIO.write(image,"png",bytes);
            var uploaded=request("POST","/api/v1/admin/images",json.writeValueAsString(java.util.Map.of("base64",java.util.Base64.getEncoder().encodeToString(bytes.toByteArray()))),token);
            http.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(uploaded.path("url").asText()))
               .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk())
               .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.content().contentType("image/png"));
            body.put("imageUrl",uploaded.path("url").asText());body.put("publicationStatus","PUBLISHED");body.put("initialPrice",39);body.put("version",draft.path("version").asLong());
            var published=request("PUT","/api/v1/admin/products/"+id,json.writeValueAsString(body),token);
            var visible=request("GET","/api/v1/products/"+id,"",token);
            assertEquals(39,visible.path("sellingPrice").asInt());assertTrue(visible.path("inStock").asBoolean());
            assertEquals(uploaded.path("url").asText(),visible.path("imageUrl").asText());
            body.remove("initialPrice");body.put("version",published.path("version").asLong());body.put("available",false);
            var unavailable=request("PUT","/api/v1/admin/products/"+id,json.writeValueAsString(body),token);
            assertFalse(request("GET","/api/v1/products/"+id,"",token).path("inStock").asBoolean());
            http.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post("/api/v1/baskets/current/items").header("Authorization","Bearer "+token).contentType("application/json").content("{\"productId\":\""+id+"\",\"quantity\":1}"))
               .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
            body.put("version",unavailable.path("version").asLong());body.put("publicationStatus","ARCHIVED");
            request("PUT","/api/v1/admin/products/"+id,json.writeValueAsString(body),token);
            denied("GET","/api/v1/products/"+id,token,404);
            assertEquals(4,db.queryForObject("select count(*) from admin_audit where entity_id=?",Integer.class,UUID.fromString(id)));
        } finally {props.getOtp().setDevMode(true);}
    }
    UUID user, product;
    @BeforeEach void seed() {
        user = UUID.randomUUID();
        db.update("insert into users(id,mobile,name) values (?,?,?)", user, user.toString().substring(0,18), "Integration household");
        db.update("insert into addresses(user_id,line1,city,pincode,is_serviceable,is_default) values (?, 'Test address', 'Hyderabad', '500081', true, true)", user);
        product = db.queryForObject("select product_id from product_prices where active=true and effective_from <= now() and (effective_to is null or effective_to > now()) limit 1", UUID.class);
    }
    @Test void upgradesV20AndValidatesEntireHibernateSchema() {
        assertEquals(23, db.queryForObject("select count(*) from flyway_schema_history where success=true and version is not null", Integer.class));
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
