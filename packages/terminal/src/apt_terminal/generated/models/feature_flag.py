from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="FeatureFlag")


@_attrs_define
class FeatureFlag:
    """
    Attributes:
        id (int):
        key (str):
        description (str):
        enabled (bool):
        created_at (str):
        updated_at (str):
    """

    id: int
    key: str
    description: str
    enabled: bool
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        key = self.key

        description = self.description

        enabled = self.enabled

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "key": key,
                "description": description,
                "enabled": enabled,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        key = d.pop("key")

        description = d.pop("description")

        enabled = d.pop("enabled")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        feature_flag = cls(
            id=id,
            key=key,
            description=description,
            enabled=enabled,
            created_at=created_at,
            updated_at=updated_at,
        )

        feature_flag.additional_properties = d
        return feature_flag

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
