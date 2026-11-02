from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GamificationSeasonsType0")


@_attrs_define
class GamificationSeasonsType0:
    """
    Attributes:
        anchor (str): Season 0 start day (YYYY-MM-DD, UTC)
        length_days (int): Days per season
    """

    anchor: str
    length_days: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        anchor = self.anchor

        length_days = self.length_days

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "anchor": anchor,
                "lengthDays": length_days,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        anchor = d.pop("anchor")

        length_days = d.pop("lengthDays")

        gamification_seasons_type_0 = cls(
            anchor=anchor,
            length_days=length_days,
        )

        gamification_seasons_type_0.additional_properties = d
        return gamification_seasons_type_0

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
