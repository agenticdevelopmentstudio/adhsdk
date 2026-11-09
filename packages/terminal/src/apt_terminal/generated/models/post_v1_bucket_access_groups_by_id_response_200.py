from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.bucket_access_group_metadata_type_0 import BucketAccessGroupMetadataType0


T = TypeVar("T", bound="PostV1BucketAccessGroupsByIdResponse200")


@_attrs_define
class PostV1BucketAccessGroupsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str): owning ecosystem
        bucket_id (str):
        name (str):
        description (str):
        kind (str): 'everyone' (seeded) or 'custom'
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        metadata (BucketAccessGroupMetadataType0 | None | Unset):
        object_ (Literal['bucket_access_group'] | Unset):
    """

    id: str
    ecosystem_id: str
    bucket_id: str
    name: str
    description: str
    kind: str
    created: int
    updated: int
    metadata: BucketAccessGroupMetadataType0 | None | Unset = UNSET
    object_: Literal["bucket_access_group"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.bucket_access_group_metadata_type_0 import (
            BucketAccessGroupMetadataType0,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        bucket_id = self.bucket_id

        name = self.name

        description = self.description

        kind = self.kind

        created = self.created

        updated = self.updated

        metadata: dict[str, Any] | None | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, BucketAccessGroupMetadataType0):
            metadata = self.metadata.to_dict()
        else:
            metadata = self.metadata

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "bucket_id": bucket_id,
                "name": name,
                "description": description,
                "kind": kind,
                "created": created,
                "updated": updated,
            }
        )
        if metadata is not UNSET:
            field_dict["metadata"] = metadata
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.bucket_access_group_metadata_type_0 import (
            BucketAccessGroupMetadataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        bucket_id = d.pop("bucket_id")

        name = d.pop("name")

        description = d.pop("description")

        kind = d.pop("kind")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_metadata(data: object) -> BucketAccessGroupMetadataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0 = BucketAccessGroupMetadataType0.from_dict(data)

                return metadata_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(BucketAccessGroupMetadataType0 | None | Unset, data)

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        object_ = cast(Literal["bucket_access_group"] | Unset, d.pop("object", UNSET))
        if object_ != "bucket_access_group" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'bucket_access_group', got '{object_}'")

        post_v1_bucket_access_groups_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            bucket_id=bucket_id,
            name=name,
            description=description,
            kind=kind,
            created=created,
            updated=updated,
            metadata=metadata,
            object_=object_,
        )

        post_v1_bucket_access_groups_by_id_response_200.additional_properties = d
        return post_v1_bucket_access_groups_by_id_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
