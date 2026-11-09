from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_catalog_badge import GamificationCatalogBadge
    from ..models.gamification_catalog_level import GamificationCatalogLevel


T = TypeVar("T", bound="GetV1GamificationCatalogResponse200")


@_attrs_define
class GetV1GamificationCatalogResponse200:
    """
    Attributes:
        badges (list[GamificationCatalogBadge]):
        levels (list[GamificationCatalogLevel]):
        object_ (Literal['gamification.catalog'] | Unset):
    """

    badges: list[GamificationCatalogBadge]
    levels: list[GamificationCatalogLevel]
    object_: Literal["gamification.catalog"] | Unset = UNSET
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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "badges": badges,
                "levels": levels,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["gamification.catalog"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.catalog" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.catalog', got '{object_}'")

        get_v1_gamification_catalog_response_200 = cls(
            badges=badges,
            levels=levels,
            object_=object_,
        )

        get_v1_gamification_catalog_response_200.additional_properties = d
        return get_v1_gamification_catalog_response_200

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
