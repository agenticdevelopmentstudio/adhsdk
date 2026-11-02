from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.gamification_catalog_badge import GamificationCatalogBadge
    from ..models.gamification_catalog_level import GamificationCatalogLevel


T = TypeVar("T", bound="GamificationCatalog")


@_attrs_define
class GamificationCatalog:
    """
    Attributes:
        badges (list[GamificationCatalogBadge]):
        levels (list[GamificationCatalogLevel]):
    """

    badges: list[GamificationCatalogBadge]
    levels: list[GamificationCatalogLevel]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        badges = []
        for badges_item_data in self.badges:
            badges_item = badges_item_data.to_dict()
            badges.append(badges_item)

        levels = []
        for levels_item_data in self.levels:
            levels_item = levels_item_data.to_dict()
            levels.append(levels_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "badges": badges,
                "levels": levels,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_catalog_badge import GamificationCatalogBadge
        from ..models.gamification_catalog_level import GamificationCatalogLevel

        d = dict(src_dict)
        badges = []
        _badges = d.pop("badges")
        for badges_item_data in _badges:
            badges_item = GamificationCatalogBadge.from_dict(badges_item_data)

            badges.append(badges_item)

        levels = []
        _levels = d.pop("levels")
        for levels_item_data in _levels:
            levels_item = GamificationCatalogLevel.from_dict(levels_item_data)

            levels.append(levels_item)

        gamification_catalog = cls(
            badges=badges,
            levels=levels,
        )

        gamification_catalog.additional_properties = d
        return gamification_catalog

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
