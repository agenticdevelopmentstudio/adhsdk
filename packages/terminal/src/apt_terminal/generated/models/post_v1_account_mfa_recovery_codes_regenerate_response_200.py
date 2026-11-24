from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccountMfaRecoveryCodesRegenerateResponse200")


@_attrs_define
class PostV1AccountMfaRecoveryCodesRegenerateResponse200:
    """
    Attributes:
        codes (list[str]):
        object_ (Literal['account.mfa.recovery_code'] | Unset):
    """

    codes: list[str]
    object_: Literal["account.mfa.recovery_code"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        codes = self.codes

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "codes": codes,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        codes = cast(list[str], d.pop("codes"))

        object_ = cast(Literal["account.mfa.recovery_code"] | Unset, d.pop("object", UNSET))
        if object_ != "account.mfa.recovery_code" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'account.mfa.recovery_code', got '{object_}'"
            )

        post_v1_account_mfa_recovery_codes_regenerate_response_200 = cls(
            codes=codes,
            object_=object_,
        )

        post_v1_account_mfa_recovery_codes_regenerate_response_200.additional_properties = d
        return post_v1_account_mfa_recovery_codes_regenerate_response_200

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
