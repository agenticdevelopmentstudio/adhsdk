from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_badge import GamificationBadge


T = TypeVar("T", bound="PostV1GamificationEventsResponse200")


@_attrs_define
class PostV1GamificationEventsResponse200:
    """
    Attributes:
        ingested (bool): false ⇒ the dedupeKey was already seen (no-op)
        stat_key (str):
        new_badges (list[GamificationBadge]):
        xp_gained (int):
        object_ (Literal['gamification.event'] | Unset):
    """

    ingested: bool
    stat_key: str
    new_badges: list[GamificationBadge]
    xp_gained: int
    object_: Literal["gamification.event"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ingested = self.ingested

        stat_key = self.stat_key

        new_badges = []
        for new_badges_item_data in self.new_badges:
            new_badges_item = new_badges_item_data.to_dict()
            new_badges.append(new_badges_item)

        xp_gained = self.xp_gained

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ingested": ingested,
                "stat_key": stat_key,
                "new_badges": new_badges,
                "xp_gained": xp_gained,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_badge import GamificationBadge

        d = dict(src_dict)
        ingested = d.pop("ingested")

        stat_key = d.pop("stat_key")

        new_badges = []
        _new_badges = d.pop("new_badges")
        for new_badges_item_data in _new_badges:
            new_badges_item = GamificationBadge.from_dict(new_badges_item_data)

            new_badges.append(new_badges_item)

        xp_gained = d.pop("xp_gained")

        object_ = cast(Literal["gamification.event"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.event', got '{object_}'")

        post_v1_gamification_events_response_200 = cls(
            ingested=ingested,
            stat_key=stat_key,
            new_badges=new_badges,
            xp_gained=xp_gained,
            object_=object_,
        )

        post_v1_gamification_events_response_200.additional_properties = d
        return post_v1_gamification_events_response_200

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
