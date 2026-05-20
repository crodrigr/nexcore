package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
public class UserInfo {
    private final UUID id;
    private final String username;
    private final String name;
    private final String email;
    private final String phone;
    private final String photo;
    private final List<String> roles;
}
