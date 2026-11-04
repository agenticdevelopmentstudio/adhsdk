from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_bucket_buckets_body_metadata_type_0_type_1 import (
        PostBucketBucketsBodyMetadataType0Type1,
    )


T = TypeVar("T", bound="PostBucketBucketsBody")


@_attrs_define
class PostBucketBucketsBody:
    """
    Attributes:
        name (str):
        slug (str):
        ecosystem_id (str | Unset):
        parent_id (None | str | Unset):
        description (str | Unset):
        kind (str | Unset):
        metadata (bool | float | list[Any] | None | PostBucketBucketsBodyMetadataType0Type1 | str | Unset):
        id (str | Unset):
    """

    name: str
    slug: str
    ecosystem_id: str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    description: str | Unset = UNSET
    kind: str | Unset = UNSET
    metadata: (
        bool | float | list[Any] | None | PostBucketBucketsBodyMetadataType0Type1 | str | Unset
    ) = UNSET
    id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_bucket_buckets_body_metadata_type_0_type_1 import (
            PostBucketBucketsBodyMetadataType0Type1,
        )

        name = self.name

        slug = self.slug

        ecosystem_id = self.ecosystem_id

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        description = self.description

        kind = self.kind

        metadata: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, PostBucketBucketsBodyMetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        id = self.id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
                "slug": slug,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if parent_id is not UNSET:
            field_dict["parentId"] = parent_id
        if description is not UNSET:
            field_dict["description"] = description
        if kind is not UNSET:
            field_dict["kind"] = kind
        if metadata is not UNSET:
            field_dict["metadata"] = metadata
        if id is not UNSET:
            field_dict["id"] = id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_bucket_buckets_body_metadata_type_0_type_1 import (
            PostBucketBucketsBodyMetadataType0Type1,
        )

        d = dict(src_dict)
        name = d.pop("name")

        slug = d.pop("slug")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parentId", UNSET))

        description = d.pop("description", UNSET)

        kind = d.pop("kind", UNSET)

        def _parse_metadata(
            data: object,
        ) -> (
            bool | float | list[Any] | None | PostBucketBucketsBodyMetadataType0Type1 | str | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = PostBucketBucketsBodyMetadataType0Type1.from_dict(data)

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
                | PostBucketBucketsBodyMetadataType0Type1
                | str
                | Unset,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        id = d.pop("id", UNSET)

        post_bucket_buckets_body = cls(
            name=name,
            slug=slug,
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            description=description,
            kind=kind,
            metadata=metadata,
            id=id,
        )

        return post_bucket_buckets_body
