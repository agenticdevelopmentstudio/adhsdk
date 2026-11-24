from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.bucket_access_group import BucketAccessGroup


T = TypeVar("T", bound="BucketAccessGroupList")


@_attrs_define
class BucketAccessGroupList:
    """
    Attributes:
        access_groups (list[BucketAccessGroup]):
    """

    access_groups: list[BucketAccessGroup]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        access_groups = []
        for access_groups_item_data in self.access_groups:
            access_groups_item = access_groups_item_data.to_dict()
            access_groups.append(access_groups_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "access_groups": access_groups,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.bucket_access_group import BucketAccessGroup

        d = dict(src_dict)
        access_groups = []
        _access_groups = d.pop("access_groups")
        for access_groups_item_data in _access_groups:
            access_groups_item = BucketAccessGroup.from_dict(access_groups_item_data)

            access_groups.append(access_groups_item)

        bucket_access_group_list = cls(
            access_groups=access_groups,
        )

        bucket_access_group_list.additional_properties = d
        return bucket_access_group_list

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
