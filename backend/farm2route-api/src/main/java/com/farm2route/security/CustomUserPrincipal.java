package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;
import java.util.UUID;

@Getter
public class CustomUserPrincipal implements UserDetails {

    private final UUID id;
    private final String phoneNumber;
    private final String email;
    private final String password;
    private final Role role;
    private final UserStatus status;
    private final boolean phoneVerified;
    private final User user;
    private final Collection<? extends GrantedAuthority> authorities;

    public CustomUserPrincipal(User user) {
        this.id = user.getId();
        this.phoneNumber = user.getPhoneNumber();
        this.email = user.getEmail();
        this.password = user.getPasswordHash();
        this.role = user.getRole();
        this.status = user.getStatus();
        this.phoneVerified = user.isPhoneVerified();
        this.user = user;
        this.authorities = Collections.singletonList(
                new SimpleGrantedAuthority(user.getRole().getAuthority())
        );
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return id.toString();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return user.isAccountNonLocked();
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return user.isEnabled();
    }
}
