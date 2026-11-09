from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_league_stat_key import GamificationLeagueStatKey
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_board_entry import GamificationBoardEntry


T = TypeVar("T", bound="GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200")


@_attrs_define
class GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200:
    """
    Attributes:
        stat_key (GamificationLeagueStatKey):
        league (int): Zero-based league cohort (30 ranks each, by season standing).
        entries (list[GamificationBoardEntry]):
        object_ (Literal['league'] | Unset):
    """

    stat_key: GamificationLeagueStatKey
    league: int
    entries: list[GamificationBoardEntry]
    object_: Literal["league"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        stat_key = self.stat_key.value

        league = self.league

        entries = []
        for entries_item_data in self.entries:
            entries_item = entries_item_data.to_dict()
            entries.append(entries_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "stat_key": stat_key,
                "league": league,
                "entries": entries,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_board_entry import GamificationBoardEntry

        d = dict(src_dict)
        stat_key = GamificationLeagueStatKey(d.pop("stat_key"))

        league = d.pop("league")

        entries = []
        _entries = d.pop("entries")
        for entries_item_data in _entries:
            entries_item = GamificationBoardEntry.from_dict(entries_item_data)

            entries.append(entries_item)

        object_ = cast(Literal["league"] | Unset, d.pop("object", UNSET))
        if object_ != "league" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'league', got '{object_}'")

        get_v1_gamification_leaderboards_by_stat_key_leagues_response_200 = cls(
            stat_key=stat_key,
            league=league,
            entries=entries,
            object_=object_,
        )

        get_v1_gamification_leaderboards_by_stat_key_leagues_response_200.additional_properties = d
        return get_v1_gamification_leaderboards_by_stat_key_leagues_response_200

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
