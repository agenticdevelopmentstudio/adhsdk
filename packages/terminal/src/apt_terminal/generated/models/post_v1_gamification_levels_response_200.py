from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_catalog_level import GamificationCatalogLevel


T = TypeVar("T", bound="PostV1GamificationLevelsResponse200")


@_attrs_define
class PostV1GamificationLevelsResponse200:
    """
    Attributes:
        levels (list[GamificationCatalogLevel]):
        replay_hint (str): The owner may POST /replay to backfill retroactively
        object_ (Literal['gamification.level'] | Unset):
    """

    levels: list[GamificationCatalogLevel]
    replay_hint: str
    object_: Literal["gamification.level"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        levels = []
        for levels_item_data in self.levels:
            levels_item = levels_item_data.to_dict()
            levels.append(levels_item)

        replay_hint = self.replay_hint

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "levels": levels,
                "replay_hint": replay_hint,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        replay_hint = d.pop("replay_hint")

        object_ = cast(Literal["gamification.level"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.level" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.level', got '{object_}'")

        post_v1_gamification_levels_response_200 = cls(
            levels=levels,
            replay_hint=replay_hint,
            object_=object_,
        )

        post_v1_gamification_levels_response_200.additional_properties = d
        return post_v1_gamification_levels_response_200

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
