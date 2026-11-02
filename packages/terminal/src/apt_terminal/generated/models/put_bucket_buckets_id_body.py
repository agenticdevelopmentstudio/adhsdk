from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_bucket_buckets_id_body_metadata_type_0_type_1 import (
        PutBucketBucketsIdBodyMetadataType0Type1,
    )


T = TypeVar("T", bound="PutBucketBucketsIdBody")


@_attrs_define
class PutBucketBucketsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        parent_id (None | str | Unset):
        name (str | Unset):
        description (str | Unset):
        kind (str | Unset):
        metadata (bool | float | list[Any] | None | PutBucketBucketsIdBodyMetadataType0Type1 | str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    kind: str | Unset = UNSET
    metadata: (
        bool | float | list[Any] | None | PutBucketBucketsIdBodyMetadataType0Type1 | str | Unset
    ) = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.put_bucket_buckets_id_body_metadata_type_0_type_1 import (
            PutBucketBucketsIdBodyMetadataType0Type1,
        )

        ecosystem_id = self.ecosystem_id

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        name = self.name

        description = self.description

        kind = self.kind

        metadata: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, PutBucketBucketsIdBodyMetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if parent_id is not UNSET:
            field_dict["parentId"] = parent_id
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if kind is not UNSET:
            field_dict["kind"] = kind
        if metadata is not UNSET:
            field_dict["metadata"] = metadata
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_bucket_buckets_id_body_metadata_type_0_type_1 import (
            PutBucketBucketsIdBodyMetadataType0Type1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parentId", UNSET))

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        kind = d.pop("kind", UNSET)

        def _parse_metadata(
            data: object,
        ) -> (
            bool | float | list[Any] | None | PutBucketBucketsIdBodyMetadataType0Type1 | str | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = PutBucketBucketsIdBodyMetadataType0Type1.from_dict(data)

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
                | PutBucketBucketsIdBodyMetadataType0Type1
                | str
                | Unset,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        sync_txid = d.pop("syncTxid", UNSET)

        put_bucket_buckets_id_body = cls(
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            name=name,
            description=description,
            kind=kind,
            metadata=metadata,
            sync_txid=sync_txid,
        )

        return put_bucket_buckets_id_body
