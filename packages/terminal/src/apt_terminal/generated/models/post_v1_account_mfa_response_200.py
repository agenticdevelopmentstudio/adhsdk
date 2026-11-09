from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_account_mfa_response_200_preferred_method import (
    PostV1AccountMfaResponse200PreferredMethod,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_account_mfa_response_200_preference import (
        PostV1AccountMfaResponse200Preference,
    )


T = TypeVar("T", bound="PostV1AccountMfaResponse200")


@_attrs_define
class PostV1AccountMfaResponse200:
    """
    Attributes:
        preferred_method (PostV1AccountMfaResponse200PreferredMethod):
        object_ (Literal['account.mfa'] | Unset):
        preference (PostV1AccountMfaResponse200Preference | Unset):
    """

    preferred_method: PostV1AccountMfaResponse200PreferredMethod
    object_: Literal["account.mfa"] | Unset = UNSET
    preference: PostV1AccountMfaResponse200Preference | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preferred_method = self.preferred_method.value

        object_ = self.object_

        preference: dict[str, Any] | Unset = UNSET
        if not isinstance(self.preference, Unset):
            preference = self.preference.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "preferred_method": preferred_method,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if preference is not UNSET:
            field_dict["preference"] = preference

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_account_mfa_response_200_preference import (
            PostV1AccountMfaResponse200Preference,
        )

        d = dict(src_dict)
        preferred_method = PostV1AccountMfaResponse200PreferredMethod(d.pop("preferred_method"))

        object_ = cast(Literal["account.mfa"] | Unset, d.pop("object", UNSET))
        if object_ != "account.mfa" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'account.mfa', got '{object_}'")

        _preference = d.pop("preference", UNSET)
        preference: PostV1AccountMfaResponse200Preference | Unset
        if isinstance(_preference, Unset):
            preference = UNSET
        else:
            preference = PostV1AccountMfaResponse200Preference.from_dict(_preference)

        post_v1_account_mfa_response_200 = cls(
            preferred_method=preferred_method,
            object_=object_,
            preference=preference,
        )

        post_v1_account_mfa_response_200.additional_properties = d
        return post_v1_account_mfa_response_200

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
