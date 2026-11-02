from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.gamification_board_entry_persona import GamificationBoardEntryPersona


T = TypeVar("T", bound="GamificationBoardEntry")


@_attrs_define
class GamificationBoardEntry:
    """
    Attributes:
        rank (int): 1-based rank among the surviving (public) entries
        value (int): The window's ranking value: rolling30 → 30-day sum, allTime → all-time total, trending → raw
            recent-7d sum (the hotness score only orders; it is not returned).
        persona (GamificationBoardEntryPersona):
    """

    rank: int
    value: int
    persona: GamificationBoardEntryPersona
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rank = self.rank

        value = self.value

        persona = self.persona.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rank": rank,
                "value": value,
                "persona": persona,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_board_entry_persona import (
            GamificationBoardEntryPersona,
        )

        d = dict(src_dict)
        rank = d.pop("rank")

        value = d.pop("value")

        persona = GamificationBoardEntryPersona.from_dict(d.pop("persona"))

        gamification_board_entry = cls(
            rank=rank,
            value=value,
            persona=persona,
        )

        gamification_board_entry.additional_properties = d
        return gamification_board_entry

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
