from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_board_stat_key import GamificationBoardStatKey
from ..models.gamification_board_window import GamificationBoardWindow

if TYPE_CHECKING:
    from ..models.gamification_board_entry import GamificationBoardEntry


T = TypeVar("T", bound="GamificationBoard")


@_attrs_define
class GamificationBoard:
    """
    Attributes:
        stat_key (GamificationBoardStatKey):
        window (GamificationBoardWindow):
        entries (list[GamificationBoardEntry]):
    """

    stat_key: GamificationBoardStatKey
    window: GamificationBoardWindow
    entries: list[GamificationBoardEntry]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        stat_key = self.stat_key.value

        window = self.window.value

        entries = []
        for entries_item_data in self.entries:
            entries_item = entries_item_data.to_dict()
            entries.append(entries_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "statKey": stat_key,
                "window": window,
                "entries": entries,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_board_entry import GamificationBoardEntry

        d = dict(src_dict)
        stat_key = GamificationBoardStatKey(d.pop("statKey"))

        window = GamificationBoardWindow(d.pop("window"))

        entries = []
        _entries = d.pop("entries")
        for entries_item_data in _entries:
            entries_item = GamificationBoardEntry.from_dict(entries_item_data)

            entries.append(entries_item)

        gamification_board = cls(
            stat_key=stat_key,
            window=window,
            entries=entries,
        )

        gamification_board.additional_properties = d
        return gamification_board

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
