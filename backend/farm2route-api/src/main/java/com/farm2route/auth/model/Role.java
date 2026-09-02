package com.farm2route.auth.model;

public enum Role {
    FARMER,
    AGENCY,
    DRIVER,
    ADMIN;

    public String getAuthority() {
        return "ROLE_" + this.name();
    }
}
