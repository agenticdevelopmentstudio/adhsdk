from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="EcosystemFeatureFlag")


@_attrs_define
class EcosystemFeatureFlag:
    """
    Attributes:
        key (str):
        enabled (bool):
        description (str):
        created_at (str):
        updated_at (str):
    """

    key: str
    enabled: bool
    description: str
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        enabled = self.enabled

        description = self.description

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "enabled": enabled,
                "description": description,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        enabled = d.pop("enabled")

        description = d.pop("description")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        ecosystem_feature_flag = cls(
            key=key,
            enabled=enabled,
            description=description,
            created_at=created_at,
            updated_at=updated_at,
        )

        ecosystem_feature_flag.additional_properties = d
        return ecosystem_feature_flag

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
