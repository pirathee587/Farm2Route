package com.farm2route.common.enums;

public enum Role {
    FARMER,
    AGENCY,
    DRIVER,
    ADMIN;

    public String getAuthority() {
        return "ROLE_" + this.name();
    }
}
