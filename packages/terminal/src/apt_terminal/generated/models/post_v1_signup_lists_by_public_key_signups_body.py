from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1SignupListsByPublicKeySignupsBody")


@_attrs_define
class PostV1SignupListsByPublicKeySignupsBody:
    """
    Attributes:
        email (str):
        nonce (str):
        name (str | Unset):
        source_url (str | Unset):
        website (str | Unset): Honeypot. The real form renders it hidden and never fills it — any value means a bot.
            Documented because a client that omits it entirely is fine, and one that FILLS it is silently accepted-and-
            discarded rather than rejected.
    """

    email: str
    nonce: str
    name: str | Unset = UNSET
    source_url: str | Unset = UNSET
    website: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        email = self.email

        nonce = self.nonce

        name = self.name

        source_url = self.source_url

        website = self.website

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "email": email,
                "nonce": nonce,
            }
        )
        if name is not UNSET:
            field_dict["name"] = name
        if source_url is not UNSET:
            field_dict["source_url"] = source_url
        if website is not UNSET:
            field_dict["website"] = website

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        email = d.pop("email")

        nonce = d.pop("nonce")

        name = d.pop("name", UNSET)

        source_url = d.pop("source_url", UNSET)

        website = d.pop("website", UNSET)

        post_v1_signup_lists_by_public_key_signups_body = cls(
            email=email,
            nonce=nonce,
            name=name,
            source_url=source_url,
            website=website,
        )

        post_v1_signup_lists_by_public_key_signups_body.additional_properties = d
        return post_v1_signup_lists_by_public_key_signups_body

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
