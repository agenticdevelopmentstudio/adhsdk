from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_buckets_response_201_metadata_type_0_type_1 import (
        PostV1BucketsResponse201MetadataType0Type1,
    )


T = TypeVar("T", bound="PostV1BucketsResponse201")


@_attrs_define
class PostV1BucketsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        parent_id (None | str):
        name (str):
        slug (str):
        description (str):
        kind (str):
        metadata (bool | float | list[Any] | None | PostV1BucketsResponse201MetadataType0Type1 | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['bucket'] | Unset):
    """

    id: str
    ecosystem_id: str
    parent_id: None | str
    name: str
    slug: str
    description: str
    kind: str
    metadata: bool | float | list[Any] | None | PostV1BucketsResponse201MetadataType0Type1 | str
    created: int
    updated: int
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["bucket"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_buckets_response_201_metadata_type_0_type_1 import (
            PostV1BucketsResponse201MetadataType0Type1,
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
        if isinstance(self.metadata, PostV1BucketsResponse201MetadataType0Type1):
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
                "parent_id": parent_id,
                "name": name,
                "slug": slug,
                "description": description,
                "kind": kind,
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
        from ..models.post_v1_buckets_response_201_metadata_type_0_type_1 import (
            PostV1BucketsResponse201MetadataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parent_id"))

        name = d.pop("name")

        slug = d.pop("slug")

        description = d.pop("description")

        kind = d.pop("kind")

        def _parse_metadata(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1BucketsResponse201MetadataType0Type1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = PostV1BucketsResponse201MetadataType0Type1.from_dict(data)

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
                bool | float | list[Any] | None | PostV1BucketsResponse201MetadataType0Type1 | str,
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

        object_ = cast(Literal["bucket"] | Unset, d.pop("object", UNSET))
        if object_ != "bucket" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'bucket', got '{object_}'")

        post_v1_buckets_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            name=name,
            slug=slug,
            description=description,
            kind=kind,
            metadata=metadata,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_buckets_response_201
