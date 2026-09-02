package com.farm2route.security;

import com.farm2route.auth.entity.User;

public class UserPrincipal extends CustomUserPrincipal {

    public UserPrincipal(User user) {
        super(user);
    }
}
