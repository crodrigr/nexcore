package com.nexore.core.module.menu.application.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MenuItemResponse {

    private final String id;
    private final String name;
    private final String title;
    private final String route;
    private final String icon;

    @JsonProperty("icon_type")
    private final String iconType;

    private final String location;

    @JsonProperty("item_type")
    private final String itemType;

    private final String access;

    @JsonProperty("order_index")
    private final int orderIndex;

    private final List<MenuItemResponse> children;
}
