package com.nayasantha.api.catalogue;
import com.nayasantha.api.common.*;
import com.nayasantha.api.security.CurrentUser;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import javax.imageio.ImageIO;
import java.io.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

@RestController
public class CatalogueImageController {
 private final JdbcTemplate db;
 public CatalogueImageController(JdbcTemplate db) {this.db=db;}
 public record Upload(@NotBlank @Size(max=1400000) String base64) {}
 @PostMapping("/api/v1/admin/images")
 public ApiResponse<Map<String,String>> upload(@Valid @RequestBody Upload request) {
  try {
   byte[] bytes=Base64.getDecoder().decode(request.base64());
   if(bytes.length>1000000) throw ApiException.userError("Choose an image smaller than 1 MB.");
   try(var input=ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
    var readers=ImageIO.getImageReaders(input);
    if(!readers.hasNext()) throw ApiException.userError("Choose a JPEG or PNG image.");
    var reader=readers.next();
    try {
     reader.setInput(input);String format=reader.getFormatName().toLowerCase(Locale.ROOT);
     if(!Set.of("jpeg","jpg","png").contains(format) || (long)reader.getWidth(0)*reader.getHeight(0)>12000000L)
      throw ApiException.userError("Choose a JPEG or PNG up to 12 megapixels.");
     var decoded=reader.read(0);var output=new ByteArrayOutputStream();
     ImageIO.write(decoded,format,output);byte[] clean=output.toByteArray();
     if(clean.length>2000000) throw ApiException.userError("Please resize the image before uploading.");
     UUID id=UUID.randomUUID();String type=format.equals("png")?"image/png":"image/jpeg";
     db.update("insert into catalogue_images(id,content_type,content,created_by) values (?,?,?,?)",id,type,clean,CurrentUser.id());
     return ApiResponse.of(Map.of("url","/api/v1/catalogue-images/"+id));
    } finally {reader.dispose();}
   }
  } catch(IOException|IllegalArgumentException e) {throw ApiException.userError("Choose a valid JPEG or PNG image.");}
 }
 @GetMapping("/api/v1/catalogue-images/{id}") public ResponseEntity<byte[]> image(@PathVariable UUID id) {
  var found=db.query("select content_type,content from catalogue_images where id=?",(r,n)->
   ResponseEntity.ok().contentType(MediaType.parseMediaType(r.getString(1)))
     .header("Cache-Control","public,max-age=86400").header("X-Content-Type-Options","nosniff").body(r.getBytes(2)),id);
  if(found.isEmpty())throw ApiException.notFound("Image");return found.get(0);
 }
}
