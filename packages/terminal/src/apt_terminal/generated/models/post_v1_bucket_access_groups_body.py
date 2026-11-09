from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BucketAccessGroupsBody")


@_attrs_define
class PostV1BucketAccessGroupsBody:
    """
    Attributes:
        name (str):
        bucket (str): Scopes the call; the caller passes it as a parameter, not in the path.
        description (str | Unset):
    """

    name: str
    bucket: str
    description: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        bucket = self.bucket

        description = self.description

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "bucket": bucket,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        bucket = d.pop("bucket")

        description = d.pop("description", UNSET)

        post_v1_bucket_access_groups_body = cls(
            name=name,
            bucket=bucket,
            description=description,
        )

        post_v1_bucket_access_groups_body.additional_properties = d
        return post_v1_bucket_access_groups_body

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
