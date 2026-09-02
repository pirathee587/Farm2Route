package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.UserStatus;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;
import java.util.UUID;

@Getter
public class UserPrincipal implements UserDetails {

    private final UUID id;
    private final String phoneNumber;
    private final String email;
    private final String password;
    private final String fullName;
    private final User user;
    private final Collection<? extends GrantedAuthority> authorities;
    private final boolean active;

    public UserPrincipal(User user) {
        this.id = user.getId();
        this.phoneNumber = user.getPhoneNumber();
        this.email = user.getEmail();
        this.password = user.getPasswordHash();
        this.fullName = user.getFullName();
        this.user = user;
        this.authorities = Collections.singletonList(
                new SimpleGrantedAuthority(user.getRole().getAuthority())
        );
        this.active = user.getStatus() != UserStatus.SUSPENDED && user.getStatus() != UserStatus.DEACTIVATED;
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
        return phoneNumber;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return active;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return active;
    }
}
