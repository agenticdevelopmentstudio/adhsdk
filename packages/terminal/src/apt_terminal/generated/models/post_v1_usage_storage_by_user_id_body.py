from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1UsageStorageByUserIdBody")


@_attrs_define
class PostV1UsageStorageByUserIdBody:
    """
    Attributes:
        quota_bytes (int): New quota in bytes (non-negative)
    """

    quota_bytes: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        quota_bytes = self.quota_bytes

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "quota_bytes": quota_bytes,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        quota_bytes = d.pop("quota_bytes")

        post_v1_usage_storage_by_user_id_body = cls(
            quota_bytes=quota_bytes,
        )

        post_v1_usage_storage_by_user_id_body.additional_properties = d
        return post_v1_usage_storage_by_user_id_body

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
