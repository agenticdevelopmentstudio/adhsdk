from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostCustomerCustomersBody")


@_attrs_define
class PostCustomerCustomersBody:
    """
    Attributes:
        slug (str):
        ecosystem_id (str | Unset):
        external_id (None | str | Unset):
        email (None | str | Unset):
        display_name (None | str | Unset):
        avatar_url (str | Unset):
        profile_visibility (str | Unset):
        preferred_mfa_method (None | str | Unset):
    """

    slug: str
    ecosystem_id: str | Unset = UNSET
    external_id: None | str | Unset = UNSET
    email: None | str | Unset = UNSET
    display_name: None | str | Unset = UNSET
    avatar_url: str | Unset = UNSET
    profile_visibility: str | Unset = UNSET
    preferred_mfa_method: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

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

        avatar_url = self.avatar_url

        profile_visibility = self.profile_visibility

        preferred_mfa_method: None | str | Unset
        if isinstance(self.preferred_mfa_method, Unset):
            preferred_mfa_method = UNSET
        else:
            preferred_mfa_method = self.preferred_mfa_method

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "slug": slug,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if external_id is not UNSET:
            field_dict["externalId"] = external_id
        if email is not UNSET:
            field_dict["email"] = email
        if display_name is not UNSET:
            field_dict["displayName"] = display_name
        if avatar_url is not UNSET:
            field_dict["avatarUrl"] = avatar_url
        if profile_visibility is not UNSET:
            field_dict["profileVisibility"] = profile_visibility
        if preferred_mfa_method is not UNSET:
            field_dict["preferredMfaMethod"] = preferred_mfa_method

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_external_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_id = _parse_external_id(d.pop("externalId", UNSET))

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

        display_name = _parse_display_name(d.pop("displayName", UNSET))

        avatar_url = d.pop("avatarUrl", UNSET)

        profile_visibility = d.pop("profileVisibility", UNSET)

        def _parse_preferred_mfa_method(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        preferred_mfa_method = _parse_preferred_mfa_method(d.pop("preferredMfaMethod", UNSET))

        post_customer_customers_body = cls(
            slug=slug,
            ecosystem_id=ecosystem_id,
            external_id=external_id,
            email=email,
            display_name=display_name,
            avatar_url=avatar_url,
            profile_visibility=profile_visibility,
            preferred_mfa_method=preferred_mfa_method,
        )

        return post_customer_customers_body
