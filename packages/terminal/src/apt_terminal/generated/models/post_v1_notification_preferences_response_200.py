from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.notification_preference import NotificationPreference


T = TypeVar("T", bound="PostV1NotificationPreferencesResponse200")


@_attrs_define
class PostV1NotificationPreferencesResponse200:
    """
    Attributes:
        preferences (list[NotificationPreference]):
        object_ (Literal['notification_preference'] | Unset):
    """

    preferences: list[NotificationPreference]
    object_: Literal["notification_preference"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preferences = []
        for preferences_item_data in self.preferences:
            preferences_item = preferences_item_data.to_dict()
            preferences.append(preferences_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "preferences": preferences,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.notification_preference import NotificationPreference

        d = dict(src_dict)
        preferences = []
        _preferences = d.pop("preferences")
        for preferences_item_data in _preferences:
            preferences_item = NotificationPreference.from_dict(preferences_item_data)

            preferences.append(preferences_item)

        object_ = cast(Literal["notification_preference"] | Unset, d.pop("object", UNSET))
        if object_ != "notification_preference" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'notification_preference', got '{object_}'")

        post_v1_notification_preferences_response_200 = cls(
            preferences=preferences,
            object_=object_,
        )

        post_v1_notification_preferences_response_200.additional_properties = d
        return post_v1_notification_preferences_response_200

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
