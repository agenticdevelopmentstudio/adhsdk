from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentSocialLinksBody")


@_attrs_define
class PostContentSocialLinksBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        platform (str | Unset):
        url (str | Unset):
        handle (str | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    platform: str | Unset = UNSET
    url: str | Unset = UNSET
    handle: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        platform = self.platform

        url = self.url

        handle = self.handle

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if platform is not UNSET:
            field_dict["platform"] = platform
        if url is not UNSET:
            field_dict["url"] = url
        if handle is not UNSET:
            field_dict["handle"] = handle
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        platform = d.pop("platform", UNSET)

        url = d.pop("url", UNSET)

        handle = d.pop("handle", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        post_content_social_links_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            platform=platform,
            url=url,
            handle=handle,
            sort_order=sort_order,
        )

        return post_content_social_links_body
