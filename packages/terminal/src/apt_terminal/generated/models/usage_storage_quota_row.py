from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageStorageQuotaRow")


@_attrs_define
class UsageStorageQuotaRow:
    """
    Attributes:
        user_id (str):
        ecosystem_id (str): Ecosystem id the override is scoped to
        quota_bytes (int):
        updated_at (str):
    """

    user_id: str
    ecosystem_id: str
    quota_bytes: int
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        ecosystem_id = self.ecosystem_id

        quota_bytes = self.quota_bytes

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "userId": user_id,
                "ecosystemId": ecosystem_id,
                "quotaBytes": quota_bytes,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("userId")

        ecosystem_id = d.pop("ecosystemId")

        quota_bytes = d.pop("quotaBytes")

        updated_at = d.pop("updatedAt")

        usage_storage_quota_row = cls(
            user_id=user_id,
            ecosystem_id=ecosystem_id,
            quota_bytes=quota_bytes,
            updated_at=updated_at,
        )

        usage_storage_quota_row.additional_properties = d
        return usage_storage_quota_row

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
