from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentSocialLinksIdBody")


@_attrs_define
class PutContentSocialLinksIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        platform (str | Unset):
        url (str | Unset):
        handle (str | Unset):
        sort_order (int | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    platform: str | Unset = UNSET
    url: str | Unset = UNSET
    handle: str | Unset = UNSET
    sort_order: int | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        platform = self.platform

        url = self.url

        handle = self.handle

        sort_order = self.sort_order

        sync_txid = self.sync_txid

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
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

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

        sync_txid = d.pop("syncTxid", UNSET)

        put_content_social_links_id_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            platform=platform,
            url=url,
            handle=handle,
            sort_order=sort_order,
            sync_txid=sync_txid,
        )

        return put_content_social_links_id_body
