from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_bucket_types_by_id_response_200_metadata_type_0_type_1 import (
        GetV1BucketTypesByIdResponse200MetadataType0Type1,
    )


T = TypeVar("T", bound="GetV1BucketTypesByIdResponse200")


@_attrs_define
class GetV1BucketTypesByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        bucket_id (str):
        sql_table_name (str):
        name (str):
        description (str):
        ref_mode (str):
        metadata (bool | float | GetV1BucketTypesByIdResponse200MetadataType0Type1 | list[Any] | None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['bucket_type'] | Unset):
    """

    id: str
    ecosystem_id: str
    bucket_id: str
    sql_table_name: str
    name: str
    description: str
    ref_mode: str
    metadata: (
        bool | float | GetV1BucketTypesByIdResponse200MetadataType0Type1 | list[Any] | None | str
    )
    created: int
    updated: int
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["bucket_type"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_v1_bucket_types_by_id_response_200_metadata_type_0_type_1 import (
            GetV1BucketTypesByIdResponse200MetadataType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        bucket_id = self.bucket_id

        sql_table_name = self.sql_table_name

        name = self.name

        description = self.description

        ref_mode = self.ref_mode

        metadata: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.metadata, GetV1BucketTypesByIdResponse200MetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        created = self.created

        updated = self.updated

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "bucket_id": bucket_id,
                "sql_table_name": sql_table_name,
                "name": name,
                "description": description,
                "ref_mode": ref_mode,
                "metadata": metadata,
                "created": created,
                "updated": updated,
                "deleted_at": deleted_at,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_bucket_types_by_id_response_200_metadata_type_0_type_1 import (
            GetV1BucketTypesByIdResponse200MetadataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        bucket_id = d.pop("bucket_id")

        sql_table_name = d.pop("sql_table_name")

        name = d.pop("name")

        description = d.pop("description")

        ref_mode = d.pop("ref_mode")

        def _parse_metadata(
            data: object,
        ) -> (
            bool
            | float
            | GetV1BucketTypesByIdResponse200MetadataType0Type1
            | list[Any]
            | None
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = (
                    GetV1BucketTypesByIdResponse200MetadataType0Type1.from_dict(data)
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
                | GetV1BucketTypesByIdResponse200MetadataType0Type1
                | list[Any]
                | None
                | str,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata"))

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["bucket_type"] | Unset, d.pop("object", UNSET))
        if object_ != "bucket_type" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'bucket_type', got '{object_}'")

        get_v1_bucket_types_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            bucket_id=bucket_id,
            sql_table_name=sql_table_name,
            name=name,
            description=description,
            ref_mode=ref_mode,
            metadata=metadata,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_bucket_types_by_id_response_200
