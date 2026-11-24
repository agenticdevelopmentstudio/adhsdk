from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_bucket_access_groups_by_id_grants_body_target_type import (
    PostV1BucketAccessGroupsByIdGrantsBodyTargetType,
)

T = TypeVar("T", bound="PostV1BucketAccessGroupsByIdGrantsBody")


@_attrs_define
class PostV1BucketAccessGroupsByIdGrantsBody:
    """
    Attributes:
        target_type (PostV1BucketAccessGroupsByIdGrantsBodyTargetType):
        target_id (str):
        crud (str): comma-separated CRUD subset (or '' for none)
    """

    target_type: PostV1BucketAccessGroupsByIdGrantsBodyTargetType
    target_id: str
    crud: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target_type = self.target_type.value

        target_id = self.target_id

        crud = self.crud

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "target_type": target_type,
                "target_id": target_id,
                "crud": crud,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_type = PostV1BucketAccessGroupsByIdGrantsBodyTargetType(d.pop("target_type"))

        target_id = d.pop("target_id")

        crud = d.pop("crud")

        post_v1_bucket_access_groups_by_id_grants_body = cls(
            target_type=target_type,
            target_id=target_id,
            crud=crud,
        )

        post_v1_bucket_access_groups_by_id_grants_body.additional_properties = d
        return post_v1_bucket_access_groups_by_id_grants_body

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
