from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.put_bucket_access_groups_group_id_grants_body_target_type import (
    PutBucketAccessGroupsGroupIdGrantsBodyTargetType,
)

T = TypeVar("T", bound="PutBucketAccessGroupsGroupIdGrantsBody")


@_attrs_define
class PutBucketAccessGroupsGroupIdGrantsBody:
    """
    Attributes:
        target_type (PutBucketAccessGroupsGroupIdGrantsBodyTargetType):
        target_id (str):
        crud (str): comma-separated CRUD subset (or '' for none)
    """

    target_type: PutBucketAccessGroupsGroupIdGrantsBodyTargetType
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
                "targetType": target_type,
                "targetId": target_id,
                "crud": crud,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_type = PutBucketAccessGroupsGroupIdGrantsBodyTargetType(d.pop("targetType"))

        target_id = d.pop("targetId")

        crud = d.pop("crud")

        put_bucket_access_groups_group_id_grants_body = cls(
            target_type=target_type,
            target_id=target_id,
            crud=crud,
        )

        put_bucket_access_groups_group_id_grants_body.additional_properties = d
        return put_bucket_access_groups_group_id_grants_body

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
