package com.nayasantha.api.catalogue;

import com.nayasantha.api.common.*;
import com.nayasantha.api.security.CurrentUser;
import com.nayasantha.api.user.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.data.domain.*;
import java.util.*;
import java.math.BigDecimal;
import java.time.*;

@RestController
@RequestMapping("/api/v1/admin")
@Transactional
public class AdminCatalogueController {
 private final ProductRepository products;
 private final CategoryRepository categories;
 private final ProductPriceRepository prices;
 private final WeeklyPricingService pricing;
 private final UserRepository users;
 private final JdbcTemplate db;
 public AdminCatalogueController(ProductRepository p, CategoryRepository c, ProductPriceRepository prices,
                                 WeeklyPricingService pricing, UserRepository u, JdbcTemplate db) {
  this.products=p; this.categories=c; this.prices=prices; this.pricing=pricing; this.users=u; this.db=db;
 }
 public record ProductInput(@NotBlank @Size(max=60) String sku, @NotBlank @Size(max=180) String name,
   @NotNull UUID categoryId, @NotBlank @Size(max=40) String unit, @Size(max=5000) String description,
   @Size(max=512) String imageUrl, @Size(max=120) String origin,
   @NotBlank @Pattern(regexp="DRAFT|PUBLISHED|ARCHIVED") String publicationStatus, boolean available,
   @DecimalMin("0.01") @Digits(integer=10,fraction=2) BigDecimal initialPrice,
   @DecimalMin("0.01") @Digits(integer=10,fraction=2) BigDecimal mrp, Long version) {}
 public record CategoryInput(@NotBlank @Size(max=120) String name,
   @NotBlank @Size(max=120) @Pattern(regexp="[a-z0-9]+(?:-[a-z0-9]+)*") String slug,
   @Size(max=16) String emoji, int sortOrder, Long version) {}
 public record StaffInput(@NotBlank @Pattern(regexp="[6-9][0-9]{9}") String mobile,
   @NotBlank @Pattern(regexp="CUSTOMER|CATALOGUE_MANAGER") String role) {}
 public record ProductView(Product product, BigDecimal sellingPrice, BigDecimal mrp) {}
 public record StaffView(UUID id, String mobile, String name, String role) {}
 @GetMapping("/me") public ApiResponse<Map<String,String>> me() {
  User u=users.findById(CurrentUser.id()).orElseThrow();
  return ApiResponse.of(Map.of("role",u.getRole().name()));
 }
 @GetMapping("/products") public ApiResponse<CatalogueDtos.PageDto<ProductView>> list(
     @RequestParam(defaultValue="0") int page) {
  Page<Product> found=products.findAll(PageRequest.of(Math.max(0,page),30,Sort.by("name").and(Sort.by("id"))));
  var rates=pricing.current(found.stream().map(Product::getId).toList());
  return ApiResponse.of(CatalogueDtos.PageDto.from(found,p -> {
   var rate=rates.get(p.getId());return new ProductView(p,rate==null?null:rate.getSellingPrice(),rate==null?null:rate.getMrp());
  }));
 }
 @GetMapping("/categories") public ApiResponse<List<Category>> categories() {
  return ApiResponse.of(categories.findAll(Sort.by("sortOrder").and(Sort.by("name"))));
 }
 @PostMapping("/categories") public ApiResponse<Category> createCategory(@Valid @RequestBody CategoryInput input) {
  return ApiResponse.of(saveCategory(new Category(),input));
 }
 @PutMapping("/categories/{id}") public ApiResponse<Category> editCategory(@PathVariable UUID id,@Valid @RequestBody CategoryInput input) {
  Category c=categories.findById(id).orElseThrow(() -> ApiException.notFound("Category"));
  checkVersion(c,input.version());return ApiResponse.of(saveCategory(c,input));
 }
 private Category saveCategory(Category c,CategoryInput input) {
  c.setName(input.name().trim());c.setSlug(input.slug());c.setEmoji(input.emoji());c.setSortOrder(input.sortOrder());
  c=categories.saveAndFlush(c);audit("CATEGORY_SAVED",c.getId(),c.getName());return c;
 }
 @PostMapping("/products") public ApiResponse<Product> create(@Valid @RequestBody ProductInput input) {
  Product p=new Product();p.setActive(false);p.setPublicationStatus("DRAFT");return ApiResponse.of(save(p,input));
 }
 @PutMapping("/products/{id}") public ApiResponse<Product> update(@PathVariable UUID id,@Valid @RequestBody ProductInput input) {
  Product p=products.findById(id).orElseThrow(() -> ApiException.notFound("Product"));
  checkVersion(p,input.version());return ApiResponse.of(save(p,input));
 }
 private Product save(Product p,ProductInput v) {
  categories.findById(v.categoryId()).filter(Category::isActive).orElseThrow(() -> ApiException.userError("Choose an active category."));
  if (v.imageUrl()!=null && !v.imageUrl().isBlank()) {
   if (!v.imageUrl().matches("/api/v1/catalogue-images/[0-9a-fA-F-]{36}")) throw ApiException.userError("Upload a product photo first.");
   UUID image=UUID.fromString(v.imageUrl().substring(v.imageUrl().lastIndexOf('/')+1));
   if (db.queryForObject("select count(*) from catalogue_images where id=?",Integer.class,image)==0) throw ApiException.userError("Photo was not found.");
  }
  if (v.mrp()!=null && v.initialPrice()!=null && v.mrp().compareTo(v.initialPrice())<0) throw ApiException.userError("MRP cannot be below selling price.");
  boolean hasPrice=p.getId()!=null && prices.existsByProductId(p.getId());
  if (hasPrice && v.initialPrice()!=null) throw ApiException.userError("Existing prices are fixed. Use weekly price publishing.");
  if ("PUBLISHED".equals(v.publicationStatus()) && !hasPrice && v.initialPrice()==null) throw ApiException.userError("Set an initial price before publishing.");
  p.setSku(v.sku().trim());p.setName(v.name().trim());p.setCategoryId(v.categoryId());p.setUnit(v.unit().trim());
  p.setDescription(v.description());p.setImageUrl(v.imageUrl());p.setOrigin(v.origin());
  p.setPublicationStatus(v.publicationStatus());p.setActive("PUBLISHED".equals(v.publicationStatus()));p.setAvailable(v.available());
  p=products.saveAndFlush(p);
  if (!hasPrice && v.initialPrice()!=null) {
   ProductPrice price=new ProductPrice();price.setProductId(p.getId());price.setSellingPrice(v.initialPrice());
   price.setForecastPrice(v.initialPrice());price.setMaxPrice(v.initialPrice());price.setMrp(v.mrp());price.setPublishedBy(CurrentUser.id());
   price.setPriceWeekStart(LocalDate.now(WeeklyPricingService.TIME_ZONE).with(java.time.temporal.TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)));
   prices.save(price);
  }
  audit("PRODUCT_SAVED",p.getId(),"status="+p.getPublicationStatus()+", available="+p.isAvailable());return p;
 }
 private void checkVersion(BaseEntity entity,Long version) {
  if (version==null || !version.equals(entity.getVersion())) throw ApiException.userError("This record changed. Reload before saving.");
 }
 @GetMapping("/staff") public ApiResponse<List<StaffView>> staff() {
  return ApiResponse.of(users.findByRoleNot(User.Role.CUSTOMER).stream().map(u -> new StaffView(u.getId(),u.getMobile(),u.getName(),u.getRole().name())).toList());
 }
 @PutMapping("/staff") public ApiResponse<StaffView> staff(@Valid @RequestBody StaffInput input) {
  User u=users.findByMobile(input.mobile()).orElseGet(() -> {User n=new User();n.setMobile(input.mobile());return n;});
  if (u.getRole()==User.Role.OWNER || CurrentUser.id().equals(u.getId())) throw ApiException.userError("The owner account cannot be changed here.");
  u.setRole(User.Role.valueOf(input.role()));u.setRoleVersion(u.getRoleVersion()+1);u=users.saveAndFlush(u);
  // Revoke refresh sessions as well as using live role checks for existing access tokens.
  db.update("update auth_sessions set revoked_at=now() where user_id=? and revoked_at is null",u.getId());
  audit("STAFF_ROLE_CHANGED",u.getId(),u.getRole().name());return ApiResponse.of(new StaffView(u.getId(),u.getMobile(),u.getName(),u.getRole().name()));
 }
 private void audit(String action,UUID id,String details) {
  db.update("insert into admin_audit(actor_id,action,entity_id,details) values (?,?,?,?)",CurrentUser.id(),action,id,details);
 }
}
