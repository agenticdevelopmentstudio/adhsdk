from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostEcosystemApplicationsBody")


@_attrs_define
class PostEcosystemApplicationsBody:
    """
    Attributes:
        slug (str):
        display_name (str):
        consumer_kind (str):
        ecosystem_id (str | Unset):
        sync_txid (int | Unset):
        id (str | Unset):
    """

    slug: str
    display_name: str
    consumer_kind: str
    ecosystem_id: str | Unset = UNSET
    sync_txid: int | Unset = UNSET
    id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name = self.display_name

        consumer_kind = self.consumer_kind

        ecosystem_id = self.ecosystem_id

        sync_txid = self.sync_txid

        id = self.id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "slug": slug,
                "displayName": display_name,
                "consumerKind": consumer_kind,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid
        if id is not UNSET:
            field_dict["id"] = id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        display_name = d.pop("displayName")

        consumer_kind = d.pop("consumerKind")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        id = d.pop("id", UNSET)

        post_ecosystem_applications_body = cls(
            slug=slug,
            display_name=display_name,
            consumer_kind=consumer_kind,
            ecosystem_id=ecosystem_id,
            sync_txid=sync_txid,
            id=id,
        )

        return post_ecosystem_applications_body
