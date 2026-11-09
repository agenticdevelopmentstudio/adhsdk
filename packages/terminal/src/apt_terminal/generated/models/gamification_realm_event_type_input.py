from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GamificationRealmEventTypeInput")


@_attrs_define
class GamificationRealmEventTypeInput:
    """
    Attributes:
        name (str): Custom event type key (≤64 chars); unique per realm
        stat_key (str): The stat this event bumps (≤64 chars)
    """

    name: str
    stat_key: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        stat_key = self.stat_key

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "stat_key": stat_key,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        stat_key = d.pop("stat_key")

        gamification_realm_event_type_input = cls(
            name=name,
            stat_key=stat_key,
        )

        gamification_realm_event_type_input.additional_properties = d
        return gamification_realm_event_type_input

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
