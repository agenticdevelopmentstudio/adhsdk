from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.put_notifications_preferences_body_preferences_item import (
        PutNotificationsPreferencesBodyPreferencesItem,
    )


T = TypeVar("T", bound="PutNotificationsPreferencesBody")


@_attrs_define
class PutNotificationsPreferencesBody:
    """
    Attributes:
        preferences (list[PutNotificationsPreferencesBodyPreferencesItem]):
    """

    preferences: list[PutNotificationsPreferencesBodyPreferencesItem]
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
        from ..models.put_notifications_preferences_body_preferences_item import (
            PutNotificationsPreferencesBodyPreferencesItem,
        )

        d = dict(src_dict)
        preferences = []
        _preferences = d.pop("preferences")
        for preferences_item_data in _preferences:
            preferences_item = PutNotificationsPreferencesBodyPreferencesItem.from_dict(
                preferences_item_data
            )

            preferences.append(preferences_item)

        put_notifications_preferences_body = cls(
            preferences=preferences,
        )

        put_notifications_preferences_body.additional_properties = d
        return put_notifications_preferences_body

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
