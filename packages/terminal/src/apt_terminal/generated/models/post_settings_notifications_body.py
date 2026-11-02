from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostSettingsNotificationsBody")


@_attrs_define
class PostSettingsNotificationsBody:
    """
    Attributes:
        category (str):
        ecosystem_id (str | Unset):
        email (bool | Unset):
        sms (bool | Unset):
        in_app (bool | Unset):
        sync_txid (int | Unset):
    """

    category: str
    ecosystem_id: str | Unset = UNSET
    email: bool | Unset = UNSET
    sms: bool | Unset = UNSET
    in_app: bool | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        category = self.category

        ecosystem_id = self.ecosystem_id

        email = self.email

        sms = self.sms

        in_app = self.in_app

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "category": category,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if email is not UNSET:
            field_dict["email"] = email
        if sms is not UNSET:
            field_dict["sms"] = sms
        if in_app is not UNSET:
            field_dict["inApp"] = in_app
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category = d.pop("category")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        email = d.pop("email", UNSET)

        sms = d.pop("sms", UNSET)

        in_app = d.pop("inApp", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        post_settings_notifications_body = cls(
            category=category,
            ecosystem_id=ecosystem_id,
            email=email,
            sms=sms,
            in_app=in_app,
            sync_txid=sync_txid,
        )

        return post_settings_notifications_body
