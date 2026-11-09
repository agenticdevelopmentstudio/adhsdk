from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CustomersByIdBody")


@_attrs_define
class PostV1CustomersByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        external_id (None | str | Unset):
        email (None | str | Unset):
        display_name (None | str | Unset):
        slug (str | Unset):
        avatar_url (str | Unset):
        profile_visibility (str | Unset):
        preferred_mfa_method (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    external_id: None | str | Unset = UNSET
    email: None | str | Unset = UNSET
    display_name: None | str | Unset = UNSET
    slug: str | Unset = UNSET
    avatar_url: str | Unset = UNSET
    profile_visibility: str | Unset = UNSET
    preferred_mfa_method: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        external_id: None | str | Unset
        if isinstance(self.external_id, Unset):
            external_id = UNSET
        else:
            external_id = self.external_id

        email: None | str | Unset
        if isinstance(self.email, Unset):
            email = UNSET
        else:
            email = self.email

        display_name: None | str | Unset
        if isinstance(self.display_name, Unset):
            display_name = UNSET
        else:
            display_name = self.display_name

        slug = self.slug

        avatar_url = self.avatar_url

        profile_visibility = self.profile_visibility

        preferred_mfa_method: None | str | Unset
        if isinstance(self.preferred_mfa_method, Unset):
            preferred_mfa_method = UNSET
        else:
            preferred_mfa_method = self.preferred_mfa_method

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if external_id is not UNSET:
            field_dict["external_id"] = external_id
        if email is not UNSET:
            field_dict["email"] = email
        if display_name is not UNSET:
            field_dict["display_name"] = display_name
        if slug is not UNSET:
            field_dict["slug"] = slug
        if avatar_url is not UNSET:
            field_dict["avatar_url"] = avatar_url
        if profile_visibility is not UNSET:
            field_dict["profile_visibility"] = profile_visibility
        if preferred_mfa_method is not UNSET:
            field_dict["preferred_mfa_method"] = preferred_mfa_method

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_external_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_id = _parse_external_id(d.pop("external_id", UNSET))

        def _parse_email(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        email = _parse_email(d.pop("email", UNSET))

        def _parse_display_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        display_name = _parse_display_name(d.pop("display_name", UNSET))

        slug = d.pop("slug", UNSET)

        avatar_url = d.pop("avatar_url", UNSET)

        profile_visibility = d.pop("profile_visibility", UNSET)

        def _parse_preferred_mfa_method(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        preferred_mfa_method = _parse_preferred_mfa_method(d.pop("preferred_mfa_method", UNSET))

        post_v1_customers_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            external_id=external_id,
            email=email,
            display_name=display_name,
            slug=slug,
            avatar_url=avatar_url,
            profile_visibility=profile_visibility,
            preferred_mfa_method=preferred_mfa_method,
        )

        return post_v1_customers_by_id_body
