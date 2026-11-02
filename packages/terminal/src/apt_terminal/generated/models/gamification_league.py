from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_league_stat_key import GamificationLeagueStatKey

if TYPE_CHECKING:
    from ..models.gamification_board_entry import GamificationBoardEntry


T = TypeVar("T", bound="GamificationLeague")


@_attrs_define
class GamificationLeague:
    """
    Attributes:
        stat_key (GamificationLeagueStatKey):
        league (int): Zero-based league cohort (30 ranks each, by season standing).
        entries (list[GamificationBoardEntry]):
    """

    stat_key: GamificationLeagueStatKey
    league: int
    entries: list[GamificationBoardEntry]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        stat_key = self.stat_key.value

        league = self.league

        entries = []
        for entries_item_data in self.entries:
            entries_item = entries_item_data.to_dict()
            entries.append(entries_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "statKey": stat_key,
                "league": league,
                "entries": entries,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_board_entry import GamificationBoardEntry

        d = dict(src_dict)
        stat_key = GamificationLeagueStatKey(d.pop("statKey"))

        league = d.pop("league")

        entries = []
        _entries = d.pop("entries")
        for entries_item_data in _entries:
            entries_item = GamificationBoardEntry.from_dict(entries_item_data)

            entries.append(entries_item)

        gamification_league = cls(
            stat_key=stat_key,
            league=league,
            entries=entries,
        )

        gamification_league.additional_properties = d
        return gamification_league

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
