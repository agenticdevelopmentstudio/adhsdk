from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1DataByTypeTagsBody")


@_attrs_define
class PostV1DataByTypeTagsBody:
    """
    Attributes:
        tag_ids (list[str]): the complete set; each must be a tag in the bucket type's ecosystem
        bucket (str): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    tag_ids: list[str]
    bucket: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tag_ids = self.tag_ids

        bucket = self.bucket

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tag_ids": tag_ids,
                "bucket": bucket,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tag_ids = cast(list[str], d.pop("tag_ids"))

        bucket = d.pop("bucket")

        post_v1_data_by_type_tags_body = cls(
            tag_ids=tag_ids,
            bucket=bucket,
        )

        post_v1_data_by_type_tags_body.additional_properties = d
        return post_v1_data_by_type_tags_body

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
