package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class UserInfoResponse {

    private final String iduser;
    private final String username;
    private final String name;
    private final String email;
    private final String phone;
    private final String photo;
    private final List<String> roles;
}
