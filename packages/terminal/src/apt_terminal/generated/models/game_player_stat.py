from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GamePlayerStat")


@_attrs_define
class GamePlayerStat:
    """
    Attributes:
        key (str):
        value (int):
        label (None | str | Unset):
        period_type (str | Unset):
        period_start (str | Unset):
    """

    key: str
    value: int
    label: None | str | Unset = UNSET
    period_type: str | Unset = UNSET
    period_start: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        value = self.value

        label: None | str | Unset
        if isinstance(self.label, Unset):
            label = UNSET
        else:
            label = self.label

        period_type = self.period_type

        period_start = self.period_start

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "value": value,
            }
        )
        if label is not UNSET:
            field_dict["label"] = label
        if period_type is not UNSET:
            field_dict["period_type"] = period_type
        if period_start is not UNSET:
            field_dict["period_start"] = period_start

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        value = d.pop("value")

        def _parse_label(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        label = _parse_label(d.pop("label", UNSET))

        period_type = d.pop("period_type", UNSET)

        period_start = d.pop("period_start", UNSET)

        game_player_stat = cls(
            key=key,
            value=value,
            label=label,
            period_type=period_type,
            period_start=period_start,
        )

        game_player_stat.additional_properties = d
        return game_player_stat

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
