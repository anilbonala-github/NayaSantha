package com.nayasantha.api.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nayasantha.api.common.ApiException;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class Msg91VerifierTest {
    private final ObjectMapper json=new ObjectMapper();
    @Test void acceptsOnlyVerifiedIndianIdentity() throws Exception {
        assertEquals("9121304215",Msg91Verifier.verifiedMobile(json.readTree("{\"type\":\"success\",\"identifier\":\"919121304215\"}")));
        assertEquals("9121304215",Msg91Verifier.verifiedMobile(json.readTree("{\"type\":\"success\",\"data\":{\"identifier\":\"919121304215\"}}")));
        assertEquals("9121304215",Msg91Verifier.verifiedMobile(json.readTree("{\"type\":\"success\",\"data\":{\"identifier\":\"+919121304215\"}}")));
    }
    @Test void rejectsConflictingOrUnverifiedTopLevelIdentity() throws Exception {
        for (String body : new String[]{
                "{\"type\":\"error\",\"identifier\":\"919121304215\"}",
                "{\"type\":\"success\",\"identifier\":\"919121304215\",\"data\":{\"identifier\":\"919704214215\"}}",
                "{\"type\":\"success\",\"identifier\":9121304215}",
                "{\"type\":\"success\",\"identifier\":\"test@example.com\"}"}) {
            var response=json.readTree(body);
            assertThrows(ApiException.class,()->Msg91Verifier.verifiedMobile(response));
        }
    }
    @Test void rejectsUnverifiedMissingOrUnsupportedIdentity() throws Exception {
        for(String body:new String[]{"{}","{\"type\":\"error\",\"data\":{\"identifier\":\"919121304215\"}}","{\"type\":\"success\"}","{\"type\":\"success\",\"data\":{\"identifier\":\"test@example.com\"}}"}) {
            var response=json.readTree(body);
            assertThrows(ApiException.class,()->Msg91Verifier.verifiedMobile(response));
        }
    }
}
