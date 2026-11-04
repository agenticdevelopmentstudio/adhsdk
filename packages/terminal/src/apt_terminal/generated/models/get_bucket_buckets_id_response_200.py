from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_bucket_buckets_id_response_200_metadata_type_0_type_1 import (
        GetBucketBucketsIdResponse200MetadataType0Type1,
    )


T = TypeVar("T", bound="GetBucketBucketsIdResponse200")


@_attrs_define
class GetBucketBucketsIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        parent_id (None | str):
        name (str):
        slug (str):
        description (str):
        kind (str):
        metadata (bool | float | GetBucketBucketsIdResponse200MetadataType0Type1 | list[Any] | None | str):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    parent_id: None | str
    name: str
    slug: str
    description: str
    kind: str
    metadata: (
        bool | float | GetBucketBucketsIdResponse200MetadataType0Type1 | list[Any] | None | str
    )
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_bucket_buckets_id_response_200_metadata_type_0_type_1 import (
            GetBucketBucketsIdResponse200MetadataType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        parent_id: None | str
        parent_id = self.parent_id

        name = self.name

        slug = self.slug

        description = self.description

        kind = self.kind

        metadata: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.metadata, GetBucketBucketsIdResponse200MetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        created_at = self.created_at

        updated_at = self.updated_at

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
                "parentId": parent_id,
                "name": name,
                "slug": slug,
                "description": description,
                "kind": kind,
                "metadata": metadata,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "deletedAt": deleted_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_bucket_buckets_id_response_200_metadata_type_0_type_1 import (
            GetBucketBucketsIdResponse200MetadataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parentId"))

        name = d.pop("name")

        slug = d.pop("slug")

        description = d.pop("description")

        kind = d.pop("kind")

        def _parse_metadata(
            data: object,
        ) -> (
            bool | float | GetBucketBucketsIdResponse200MetadataType0Type1 | list[Any] | None | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = GetBucketBucketsIdResponse200MetadataType0Type1.from_dict(
                    data
                )

                return metadata_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                metadata_type_0_type_2 = cast(list[Any], data)

                return metadata_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | GetBucketBucketsIdResponse200MetadataType0Type1
                | list[Any]
                | None
                | str,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

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

        get_bucket_buckets_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            name=name,
            slug=slug,
            description=description,
            kind=kind,
            metadata=metadata,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_bucket_buckets_id_response_200
