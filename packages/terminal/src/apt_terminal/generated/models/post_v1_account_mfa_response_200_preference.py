from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_account_mfa_response_200_preference_preferred_method import (
    PostV1AccountMfaResponse200PreferencePreferredMethod,
)

T = TypeVar("T", bound="PostV1AccountMfaResponse200Preference")


@_attrs_define
class PostV1AccountMfaResponse200Preference:
    """
    Attributes:
        preferred_method (PostV1AccountMfaResponse200PreferencePreferredMethod):
    """

    preferred_method: PostV1AccountMfaResponse200PreferencePreferredMethod
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preferred_method = self.preferred_method.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "preferred_method": preferred_method,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        preferred_method = PostV1AccountMfaResponse200PreferencePreferredMethod(
            d.pop("preferred_method")
        )

        post_v1_account_mfa_response_200_preference = cls(
            preferred_method=preferred_method,
        )

        post_v1_account_mfa_response_200_preference.additional_properties = d
        return post_v1_account_mfa_response_200_preference

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
