from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageStorageQuota")


@_attrs_define
class UsageStorageQuota:
    """
    Attributes:
        quota_bytes (int): Per-user quota in bytes (override or 5 GB default)
        usage_bytes (int): Live sum of ready, non-deleted attachment bytes
        available_bytes (int): max(0, quotaBytes - usageBytes)
    """

    quota_bytes: int
    usage_bytes: int
    available_bytes: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        quota_bytes = self.quota_bytes

        usage_bytes = self.usage_bytes

        available_bytes = self.available_bytes

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "quota_bytes": quota_bytes,
                "usage_bytes": usage_bytes,
                "available_bytes": available_bytes,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        quota_bytes = d.pop("quota_bytes")

        usage_bytes = d.pop("usage_bytes")

        available_bytes = d.pop("available_bytes")

        usage_storage_quota = cls(
            quota_bytes=quota_bytes,
            usage_bytes=usage_bytes,
            available_bytes=available_bytes,
        )

        usage_storage_quota.additional_properties = d
        return usage_storage_quota

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
