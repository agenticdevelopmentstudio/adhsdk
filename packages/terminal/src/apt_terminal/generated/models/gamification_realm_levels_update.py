from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.gamification_catalog_level import GamificationCatalogLevel


T = TypeVar("T", bound="GamificationRealmLevelsUpdate")


@_attrs_define
class GamificationRealmLevelsUpdate:
    """
    Attributes:
        levels (list[GamificationCatalogLevel]):
        replay_hint (str): The owner may POST /replay to backfill retroactively
    """

    levels: list[GamificationCatalogLevel]
    replay_hint: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        levels = []
        for levels_item_data in self.levels:
            levels_item = levels_item_data.to_dict()
            levels.append(levels_item)

        replay_hint = self.replay_hint

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "levels": levels,
                "replayHint": replay_hint,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_catalog_level import GamificationCatalogLevel

        d = dict(src_dict)
        levels = []
        _levels = d.pop("levels")
        for levels_item_data in _levels:
            levels_item = GamificationCatalogLevel.from_dict(levels_item_data)

            levels.append(levels_item)

        replay_hint = d.pop("replayHint")

        gamification_realm_levels_update = cls(
            levels=levels,
            replay_hint=replay_hint,
        )

        gamification_realm_levels_update.additional_properties = d
        return gamification_realm_levels_update

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
