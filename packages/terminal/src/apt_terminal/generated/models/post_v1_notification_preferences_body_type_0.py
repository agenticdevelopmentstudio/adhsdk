from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_notification_preferences_body_type_0_category import (
    PostV1NotificationPreferencesBodyType0Category,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1NotificationPreferencesBodyType0")


@_attrs_define
class PostV1NotificationPreferencesBodyType0:
    """
    Attributes:
        category (PostV1NotificationPreferencesBodyType0Category):
        email (bool):
        sms (bool):
        in_app (bool | Unset): In-app (inbox) delivery for this category. Omitted means true — the PUT replaces the row
            wholesale, so a client that edits only email/sms must send back the value it read.
    """

    category: PostV1NotificationPreferencesBodyType0Category
    email: bool
    sms: bool
    in_app: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        category = self.category.value

        email = self.email

        sms = self.sms

        in_app = self.in_app

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "category": category,
                "email": email,
                "sms": sms,
            }
        )
        if in_app is not UNSET:
            field_dict["in_app"] = in_app

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category = PostV1NotificationPreferencesBodyType0Category(d.pop("category"))

        email = d.pop("email")

        sms = d.pop("sms")

        in_app = d.pop("in_app", UNSET)

        post_v1_notification_preferences_body_type_0 = cls(
            category=category,
            email=email,
            sms=sms,
            in_app=in_app,
        )

        post_v1_notification_preferences_body_type_0.additional_properties = d
        return post_v1_notification_preferences_body_type_0

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
