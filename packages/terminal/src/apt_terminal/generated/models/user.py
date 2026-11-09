from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.user_profile_visibility import UserProfileVisibility

T = TypeVar("T", bound="User")


@_attrs_define
class User:
    """
    Attributes:
        id (str):
        email (str):
        name (str):
        avatar_url (str):
        slug (None | str):
        public_profile_enabled (bool): Whether the public profile card is visible at /public/users/:slug
        profile_visibility (UserProfileVisibility): The principal's page-level profile visibility. Supersedes
            publicProfileEnabled, which is retained during the expand phase and written in parallel.
        capabilities (list[str]):
    """

    id: str
    email: str
    name: str
    avatar_url: str
    slug: None | str
    public_profile_enabled: bool
    profile_visibility: UserProfileVisibility
    capabilities: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        email = self.email

        name = self.name

        avatar_url = self.avatar_url

        slug: None | str
        slug = self.slug

        public_profile_enabled = self.public_profile_enabled

        profile_visibility = self.profile_visibility.value

        capabilities = self.capabilities

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "email": email,
                "name": name,
                "avatar_url": avatar_url,
                "slug": slug,
                "public_profile_enabled": public_profile_enabled,
                "profile_visibility": profile_visibility,
                "capabilities": capabilities,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        email = d.pop("email")

        name = d.pop("name")

        avatar_url = d.pop("avatar_url")

        def _parse_slug(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        slug = _parse_slug(d.pop("slug"))

        public_profile_enabled = d.pop("public_profile_enabled")

        profile_visibility = UserProfileVisibility(d.pop("profile_visibility"))

        capabilities = cast(list[str], d.pop("capabilities"))

        user = cls(
            id=id,
            email=email,
            name=name,
            avatar_url=avatar_url,
            slug=slug,
            public_profile_enabled=public_profile_enabled,
            profile_visibility=profile_visibility,
            capabilities=capabilities,
        )

        user.additional_properties = d
        return user

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
