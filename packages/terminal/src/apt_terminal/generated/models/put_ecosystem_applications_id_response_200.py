from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutEcosystemApplicationsIdResponse200")


@_attrs_define
class PutEcosystemApplicationsIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        slug (str):
        display_name (str):
        consumer_kind (str):
        platform (str):
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    slug: str
    display_name: str
    consumer_kind: str
    platform: str
    created_at: str
    updated_at: str
    is_deleted: bool
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        slug = self.slug

        display_name = self.display_name

        consumer_kind = self.consumer_kind

        platform = self.platform

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "slug": slug,
                "displayName": display_name,
                "consumerKind": consumer_kind,
                "platform": platform,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
                "deletedAt": deleted_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        slug = d.pop("slug")

        display_name = d.pop("displayName")

        consumer_kind = d.pop("consumerKind")

        platform = d.pop("platform")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        put_ecosystem_applications_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            slug=slug,
            display_name=display_name,
            consumer_kind=consumer_kind,
            platform=platform,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return put_ecosystem_applications_id_response_200
