from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1NotificationSettingsByIdBody")


@_attrs_define
class PostV1NotificationSettingsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        category (str | Unset):
        email (bool | Unset):
        sms (bool | Unset):
        in_app (bool | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    category: str | Unset = UNSET
    email: bool | Unset = UNSET
    sms: bool | Unset = UNSET
    in_app: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        category = self.category

        email = self.email

        sms = self.sms

        in_app = self.in_app

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if category is not UNSET:
            field_dict["category"] = category
        if email is not UNSET:
            field_dict["email"] = email
        if sms is not UNSET:
            field_dict["sms"] = sms
        if in_app is not UNSET:
            field_dict["in_app"] = in_app

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        category = d.pop("category", UNSET)

        email = d.pop("email", UNSET)

        sms = d.pop("sms", UNSET)

        in_app = d.pop("in_app", UNSET)

        post_v1_notification_settings_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            category=category,
            email=email,
            sms=sms,
            in_app=in_app,
        )

        return post_v1_notification_settings_by_id_body
