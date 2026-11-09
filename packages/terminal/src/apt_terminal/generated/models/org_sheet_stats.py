from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="OrgSheetStats")


@_attrs_define
class OrgSheetStats:
    """
    Attributes:
        personas_published (int):
        days_active (int):
    """

    personas_published: int
    days_active: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        personas_published = self.personas_published

        days_active = self.days_active

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "personas_published": personas_published,
                "days_active": days_active,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        personas_published = d.pop("personas_published")

        days_active = d.pop("days_active")

        org_sheet_stats = cls(
            personas_published=personas_published,
            days_active=days_active,
        )

        org_sheet_stats.additional_properties = d
        return org_sheet_stats

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
