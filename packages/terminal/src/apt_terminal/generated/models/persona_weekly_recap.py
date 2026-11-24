from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaWeeklyRecap")


@_attrs_define
class PersonaWeeklyRecap:
    """
    Attributes:
        week_start (str):
        adventures (int):
        new_allies (int):
        reflexes_delta_pct (float | None):
        levels_gained (int):
    """

    week_start: str
    adventures: int
    new_allies: int
    reflexes_delta_pct: float | None
    levels_gained: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        week_start = self.week_start

        adventures = self.adventures

        new_allies = self.new_allies

        reflexes_delta_pct: float | None
        reflexes_delta_pct = self.reflexes_delta_pct

        levels_gained = self.levels_gained

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "week_start": week_start,
                "adventures": adventures,
                "new_allies": new_allies,
                "reflexes_delta_pct": reflexes_delta_pct,
                "levels_gained": levels_gained,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        week_start = d.pop("week_start")

        adventures = d.pop("adventures")

        new_allies = d.pop("new_allies")

        def _parse_reflexes_delta_pct(data: object) -> float | None:
            if data is None:
                return data
            return cast(float | None, data)

        reflexes_delta_pct = _parse_reflexes_delta_pct(d.pop("reflexes_delta_pct"))

        levels_gained = d.pop("levels_gained")

        persona_weekly_recap = cls(
            week_start=week_start,
            adventures=adventures,
            new_allies=new_allies,
            reflexes_delta_pct=reflexes_delta_pct,
            levels_gained=levels_gained,
        )

        persona_weekly_recap.additional_properties = d
        return persona_weekly_recap

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
