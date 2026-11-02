from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_auth_me_body_profile_visibility import PatchAuthMeBodyProfileVisibility
from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchAuthMeBody")


@_attrs_define
class PatchAuthMeBody:
    """At least one profile field is required.

    Attributes:
        name (str | Unset):
        slug (str | Unset):
        avatar_url (str | Unset):
        public_profile_enabled (bool | Unset):
        profile_visibility (PatchAuthMeBodyProfileVisibility | Unset): The principal's page-level profile visibility.
            Supersedes publicProfileEnabled, which is retained during the expand phase and written in parallel.
    """

    name: str | Unset = UNSET
    slug: str | Unset = UNSET
    avatar_url: str | Unset = UNSET
    public_profile_enabled: bool | Unset = UNSET
    profile_visibility: PatchAuthMeBodyProfileVisibility | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        slug = self.slug

        avatar_url = self.avatar_url

        public_profile_enabled = self.public_profile_enabled

        profile_visibility: str | Unset = UNSET
        if not isinstance(self.profile_visibility, Unset):
            profile_visibility = self.profile_visibility.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if slug is not UNSET:
            field_dict["slug"] = slug
        if avatar_url is not UNSET:
            field_dict["avatarUrl"] = avatar_url
        if public_profile_enabled is not UNSET:
            field_dict["publicProfileEnabled"] = public_profile_enabled
        if profile_visibility is not UNSET:
            field_dict["profileVisibility"] = profile_visibility

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        slug = d.pop("slug", UNSET)

        avatar_url = d.pop("avatarUrl", UNSET)

        public_profile_enabled = d.pop("publicProfileEnabled", UNSET)

        _profile_visibility = d.pop("profileVisibility", UNSET)
        profile_visibility: PatchAuthMeBodyProfileVisibility | Unset
        if isinstance(_profile_visibility, Unset):
            profile_visibility = UNSET
        else:
            profile_visibility = PatchAuthMeBodyProfileVisibility(_profile_visibility)

        patch_auth_me_body = cls(
            name=name,
            slug=slug,
            avatar_url=avatar_url,
            public_profile_enabled=public_profile_enabled,
            profile_visibility=profile_visibility,
        )

        patch_auth_me_body.additional_properties = d
        return patch_auth_me_body

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
