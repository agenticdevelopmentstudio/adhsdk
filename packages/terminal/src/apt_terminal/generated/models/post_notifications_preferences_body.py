from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_notifications_preferences_body_category import (
    PostNotificationsPreferencesBodyCategory,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostNotificationsPreferencesBody")


@_attrs_define
class PostNotificationsPreferencesBody:
    """
    Attributes:
        category (PostNotificationsPreferencesBodyCategory):
        email (bool):
        sms (bool):
        in_app (bool | Unset): In-app (inbox) delivery for this category. Omitted means true — the PUT replaces the row
            wholesale, so a client that edits only email/sms must send back the value it read.
    """

    category: PostNotificationsPreferencesBodyCategory
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
            field_dict["inApp"] = in_app

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category = PostNotificationsPreferencesBodyCategory(d.pop("category"))

        email = d.pop("email")

        sms = d.pop("sms")

        in_app = d.pop("inApp", UNSET)

        post_notifications_preferences_body = cls(
            category=category,
            email=email,
            sms=sms,
            in_app=in_app,
        )

        post_notifications_preferences_body.additional_properties = d
        return post_notifications_preferences_body

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
