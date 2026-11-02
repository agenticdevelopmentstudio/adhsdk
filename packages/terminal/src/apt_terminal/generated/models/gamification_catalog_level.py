from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_catalog_level_source import GamificationCatalogLevelSource

T = TypeVar("T", bound="GamificationCatalogLevel")


@_attrs_define
class GamificationCatalogLevel:
    """
    Attributes:
        name (str):
        min_points (int):
        source (GamificationCatalogLevelSource):
    """

    name: str
    min_points: int
    source: GamificationCatalogLevelSource
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        min_points = self.min_points

        source = self.source.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "minPoints": min_points,
                "source": source,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        min_points = d.pop("minPoints")

        source = GamificationCatalogLevelSource(d.pop("source"))

        gamification_catalog_level = cls(
            name=name,
            min_points=min_points,
            source=source,
        )

        gamification_catalog_level.additional_properties = d
        return gamification_catalog_level

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
