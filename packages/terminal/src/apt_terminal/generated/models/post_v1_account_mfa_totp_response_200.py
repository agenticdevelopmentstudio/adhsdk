from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccountMfaTotpResponse200")


@_attrs_define
class PostV1AccountMfaTotpResponse200:
    """
    Attributes:
        secret (str): Base32 secret (for manual entry)
        otpauth_uri (str): otpauth:// URI to render as a QR code
        object_ (Literal['account.mfa.totp'] | Unset):
    """

    secret: str
    otpauth_uri: str
    object_: Literal["account.mfa.totp"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        secret = self.secret

        otpauth_uri = self.otpauth_uri

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "secret": secret,
                "otpauth_uri": otpauth_uri,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        secret = d.pop("secret")

        otpauth_uri = d.pop("otpauth_uri")

        object_ = cast(Literal["account.mfa.totp"] | Unset, d.pop("object", UNSET))
        if object_ != "account.mfa.totp" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'account.mfa.totp', got '{object_}'")

        post_v1_account_mfa_totp_response_200 = cls(
            secret=secret,
            otpauth_uri=otpauth_uri,
            object_=object_,
        )

        post_v1_account_mfa_totp_response_200.additional_properties = d
        return post_v1_account_mfa_totp_response_200

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
