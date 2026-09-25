package com.nayasantha.api.auth;
import com.nayasantha.api.config.AppProperties;
import com.nayasantha.api.common.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class Msg91AuthControllerTest {
    final Msg91Verifier provider=mock(Msg91Verifier.class);
    final AuthService auth=mock(AuthService.class);
    final JdbcTemplate db=mock(JdbcTemplate.class);
    final AppProperties props=new AppProperties();
    Msg91AuthController controller() { return new Msg91AuthController(provider,auth,db,props,true,"widget","public-token","private-key"); }
    @Test void refusesProofWhenDummyModeIsEnabled() {
        assertThrows(ApiException.class,()->controller().verify(new Msg91AuthController.Proof("proof","9121304215",true),new MockHttpServletRequest()));
        verifyNoInteractions(provider,auth,db);
    }
    @Test void refusesDifferentMobileEvenWhenProviderApprovesProof() {
        props.getOtp().setDevMode(false);
        when(provider.verify("proof")).thenReturn("9704214215");
        assertThrows(ApiException.class,()->controller().verify(new Msg91AuthController.Proof("proof","9121304215",true),new MockHttpServletRequest()));
        verifyNoInteractions(auth,db);
    }
    @Test void refusesReusedProof() {
        props.getOtp().setDevMode(false);
        when(provider.verify("proof")).thenReturn("9121304215");
        assertThrows(ApiException.class,()->controller().verify(new Msg91AuthController.Proof("proof","9121304215",true),new MockHttpServletRequest()));
        verifyNoInteractions(auth);
    }
    @Test void onlyPassesProviderVerifiedMobileToSessionIssuer() {
        props.getOtp().setDevMode(false);
        when(provider.verify("proof")).thenReturn("9121304215");
        when(db.update(anyString(),eq(Hashing.sha256("proof")))).thenReturn(1);
        controller().verify(new Msg91AuthController.Proof("proof","9121304215",true),new MockHttpServletRequest());
        verify(auth).signInVerifiedMobile("9121304215",true,null);
    }
}
