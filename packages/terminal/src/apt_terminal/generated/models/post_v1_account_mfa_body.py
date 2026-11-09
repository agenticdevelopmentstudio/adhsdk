from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_account_mfa_body_preference import PostV1AccountMfaBodyPreference


T = TypeVar("T", bound="PostV1AccountMfaBody")


@_attrs_define
class PostV1AccountMfaBody:
    """
    Attributes:
        preference (PostV1AccountMfaBodyPreference | Unset): Updates `preference`.
    """

    preference: PostV1AccountMfaBodyPreference | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preference: dict[str, Any] | Unset = UNSET
        if not isinstance(self.preference, Unset):
            preference = self.preference.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if preference is not UNSET:
            field_dict["preference"] = preference

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_account_mfa_body_preference import (
            PostV1AccountMfaBodyPreference,
        )

        d = dict(src_dict)
        _preference = d.pop("preference", UNSET)
        preference: PostV1AccountMfaBodyPreference | Unset
        if isinstance(_preference, Unset):
            preference = UNSET
        else:
            preference = PostV1AccountMfaBodyPreference.from_dict(_preference)

        post_v1_account_mfa_body = cls(
            preference=preference,
        )

        post_v1_account_mfa_body.additional_properties = d
        return post_v1_account_mfa_body

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
