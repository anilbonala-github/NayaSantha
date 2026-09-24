package com.nayasantha.api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/** Authenticates requests carrying a valid {@code Authorization: Bearer <jwt>}. */
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    private final com.nayasantha.api.user.UserRepository users;
    private final com.nayasantha.api.config.AppProperties props;
    public JwtAuthFilter(JwtService jwtService, com.nayasantha.api.user.UserRepository users,
                         com.nayasantha.api.config.AppProperties props) {
        this.jwtService = jwtService;
        this.users = users;
        this.props = props;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header != null && header.startsWith("Bearer ")
                && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                JwtService.Principal p = jwtService.parse(header.substring(7));
                var user = users.findById(p.userId()).orElseThrow();
                if (user.getStatus() != com.nayasantha.api.user.User.Status.ACTIVE) throw new IllegalStateException();
                // Do not elevate an old customer token after a role change; require fresh login.
                String role = user.getRole().name();
                if (p.roleVersion() != user.getRoleVersion()) throw new IllegalStateException();
                if (props.getOtp().isDevMode() || !p.staffVerified() || !role.equals(p.role())) role = "CUSTOMER";
                var auth = new UsernamePasswordAuthenticationToken(
                        p.userId(), null, AuthorityUtils.createAuthorityList("ROLE_" + role));
                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (Exception ignored) {
                // Invalid/expired token -> stays unauthenticated; entry point returns 401.
            }
        }
        chain.doFilter(request, response);
    }
}
