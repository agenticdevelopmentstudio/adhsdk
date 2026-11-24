from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_account_mfa_passkeys_registration_options_body_kind import (
    PostV1AccountMfaPasskeysRegistrationOptionsBodyKind,
)

T = TypeVar("T", bound="PostV1AccountMfaPasskeysRegistrationOptionsBody")


@_attrs_define
class PostV1AccountMfaPasskeysRegistrationOptionsBody:
    """
    Attributes:
        kind (PostV1AccountMfaPasskeysRegistrationOptionsBodyKind):
    """

    kind: PostV1AccountMfaPasskeysRegistrationOptionsBodyKind
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = PostV1AccountMfaPasskeysRegistrationOptionsBodyKind(d.pop("kind"))

        post_v1_account_mfa_passkeys_registration_options_body = cls(
            kind=kind,
        )

        post_v1_account_mfa_passkeys_registration_options_body.additional_properties = d
        return post_v1_account_mfa_passkeys_registration_options_body

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
