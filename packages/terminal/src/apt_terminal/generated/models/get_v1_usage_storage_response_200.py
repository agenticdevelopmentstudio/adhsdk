from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1UsageStorageResponse200")


@_attrs_define
class GetV1UsageStorageResponse200:
    """
    Attributes:
        quota_bytes (int): Per-user quota in bytes (override or 5 GB default)
        usage_bytes (int): Live sum of ready, non-deleted attachment bytes
        available_bytes (int): max(0, quotaBytes - usageBytes)
        object_ (Literal['usage.storage'] | Unset):
    """

    quota_bytes: int
    usage_bytes: int
    available_bytes: int
    object_: Literal["usage.storage"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        quota_bytes = self.quota_bytes

        usage_bytes = self.usage_bytes

        available_bytes = self.available_bytes

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "quota_bytes": quota_bytes,
                "usage_bytes": usage_bytes,
                "available_bytes": available_bytes,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        quota_bytes = d.pop("quota_bytes")

        usage_bytes = d.pop("usage_bytes")

        available_bytes = d.pop("available_bytes")

        object_ = cast(Literal["usage.storage"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.storage" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.storage', got '{object_}'")

        get_v1_usage_storage_response_200 = cls(
            quota_bytes=quota_bytes,
            usage_bytes=usage_bytes,
            available_bytes=available_bytes,
            object_=object_,
        )

        get_v1_usage_storage_response_200.additional_properties = d
        return get_v1_usage_storage_response_200

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
