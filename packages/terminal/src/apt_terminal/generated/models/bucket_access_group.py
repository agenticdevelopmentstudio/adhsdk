from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.bucket_access_group_metadata_type_0 import BucketAccessGroupMetadataType0


T = TypeVar("T", bound="BucketAccessGroup")


@_attrs_define
class BucketAccessGroup:
    """
    Attributes:
        id (str):
        ecosystem_id (str): owning ecosystem
        bucket_id (str):
        name (str):
        description (str):
        kind (str): 'everyone' (seeded) or 'custom'
        created_at (str):
        updated_at (str):
        metadata (BucketAccessGroupMetadataType0 | None | Unset):
    """

    id: str
    ecosystem_id: str
    bucket_id: str
    name: str
    description: str
    kind: str
    created_at: str
    updated_at: str
    metadata: BucketAccessGroupMetadataType0 | None | Unset = UNSET
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

        created_at = self.created_at

        updated_at = self.updated_at

        metadata: dict[str, Any] | None | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, BucketAccessGroupMetadataType0):
            metadata = self.metadata.to_dict()
        else:
            metadata = self.metadata

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "bucketId": bucket_id,
                "name": name,
                "description": description,
                "kind": kind,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if metadata is not UNSET:
            field_dict["metadata"] = metadata

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.bucket_access_group_metadata_type_0 import (
            BucketAccessGroupMetadataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        bucket_id = d.pop("bucketId")

        name = d.pop("name")

        description = d.pop("description")

        kind = d.pop("kind")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

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

        bucket_access_group = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            bucket_id=bucket_id,
            name=name,
            description=description,
            kind=kind,
            created_at=created_at,
            updated_at=updated_at,
            metadata=metadata,
        )

        bucket_access_group.additional_properties = d
        return bucket_access_group

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
