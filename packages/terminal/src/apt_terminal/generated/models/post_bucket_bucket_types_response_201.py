from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.post_bucket_bucket_types_response_201_metadata_type_0_type_1 import (
        PostBucketBucketTypesResponse201MetadataType0Type1,
    )


T = TypeVar("T", bound="PostBucketBucketTypesResponse201")


@_attrs_define
class PostBucketBucketTypesResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        bucket_id (str):
        sql_table_name (str):
        name (str):
        description (str):
        ref_mode (str):
        metadata (bool | float | list[Any] | None | PostBucketBucketTypesResponse201MetadataType0Type1 | str):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    bucket_id: str
    sql_table_name: str
    name: str
    description: str
    ref_mode: str
    metadata: (
        bool | float | list[Any] | None | PostBucketBucketTypesResponse201MetadataType0Type1 | str
    )
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_bucket_bucket_types_response_201_metadata_type_0_type_1 import (
            PostBucketBucketTypesResponse201MetadataType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        bucket_id = self.bucket_id

        sql_table_name = self.sql_table_name

        name = self.name

        description = self.description

        ref_mode = self.ref_mode

        metadata: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.metadata, PostBucketBucketTypesResponse201MetadataType0Type1):
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
                "bucketId": bucket_id,
                "sqlTableName": sql_table_name,
                "name": name,
                "description": description,
                "refMode": ref_mode,
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
        from ..models.post_bucket_bucket_types_response_201_metadata_type_0_type_1 import (
            PostBucketBucketTypesResponse201MetadataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        bucket_id = d.pop("bucketId")

        sql_table_name = d.pop("sqlTableName")

        name = d.pop("name")

        description = d.pop("description")

        ref_mode = d.pop("refMode")

        def _parse_metadata(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostBucketBucketTypesResponse201MetadataType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = (
                    PostBucketBucketTypesResponse201MetadataType0Type1.from_dict(data)
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
                | list[Any]
                | None
                | PostBucketBucketTypesResponse201MetadataType0Type1
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

        post_bucket_bucket_types_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            bucket_id=bucket_id,
            sql_table_name=sql_table_name,
            name=name,
            description=description,
            ref_mode=ref_mode,
            metadata=metadata,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_bucket_bucket_types_response_201
