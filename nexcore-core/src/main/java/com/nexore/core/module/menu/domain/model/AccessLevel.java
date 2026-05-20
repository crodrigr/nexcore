package com.nexore.core.module.menu.domain.model;

import com.fasterxml.jackson.annotation.JsonValue;

public enum AccessLevel {

    HIDDEN(0),
    VIEW(1),
    EXECUTE(2);

    private final int order;

    AccessLevel(int order) {
        this.order = order;
    }

    public int getOrder() {
        return order;
    }

    @JsonValue
    public String toJson() {
        return name().toLowerCase();
    }

    public static AccessLevel fromInt(int value) {
        return switch (value) {
            case 0 -> HIDDEN;
            case 1 -> VIEW;
            case 2 -> EXECUTE;
            default -> HIDDEN;
        };
    }
}
