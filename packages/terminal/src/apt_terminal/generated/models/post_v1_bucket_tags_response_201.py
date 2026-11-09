from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BucketTagsResponse201")


@_attrs_define
class PostV1BucketTagsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str): owning ecosystem
        name (str): unique within the ecosystem
        description (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['bucket_tag'] | Unset):
    """

    id: str
    ecosystem_id: str
    name: str
    description: str
    created: int
    updated: int
    object_: Literal["bucket_tag"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        name = self.name

        description = self.description

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "name": name,
                "description": description,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        name = d.pop("name")

        description = d.pop("description")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["bucket_tag"] | Unset, d.pop("object", UNSET))
        if object_ != "bucket_tag" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'bucket_tag', got '{object_}'")

        post_v1_bucket_tags_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            name=name,
            description=description,
            created=created,
            updated=updated,
            object_=object_,
        )

        post_v1_bucket_tags_response_201.additional_properties = d
        return post_v1_bucket_tags_response_201

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
