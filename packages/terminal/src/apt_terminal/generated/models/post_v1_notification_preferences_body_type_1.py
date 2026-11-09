from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.post_v1_notification_preferences_body_type_1_preferences_item import (
        PostV1NotificationPreferencesBodyType1PreferencesItem,
    )


T = TypeVar("T", bound="PostV1NotificationPreferencesBodyType1")


@_attrs_define
class PostV1NotificationPreferencesBodyType1:
    """
    Attributes:
        preferences (list[PostV1NotificationPreferencesBodyType1PreferencesItem]):
    """

    preferences: list[PostV1NotificationPreferencesBodyType1PreferencesItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preferences = []
        for preferences_item_data in self.preferences:
            preferences_item = preferences_item_data.to_dict()
            preferences.append(preferences_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "preferences": preferences,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_notification_preferences_body_type_1_preferences_item import (
            PostV1NotificationPreferencesBodyType1PreferencesItem,
        )

        d = dict(src_dict)
        preferences = []
        _preferences = d.pop("preferences")
        for preferences_item_data in _preferences:
            preferences_item = PostV1NotificationPreferencesBodyType1PreferencesItem.from_dict(
                preferences_item_data
            )

            preferences.append(preferences_item)

        post_v1_notification_preferences_body_type_1 = cls(
            preferences=preferences,
        )

        post_v1_notification_preferences_body_type_1.additional_properties = d
        return post_v1_notification_preferences_body_type_1

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
