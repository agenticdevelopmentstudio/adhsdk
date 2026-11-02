from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.visitor_status_event_phase import VisitorStatusEventPhase

T = TypeVar("T", bound="VisitorStatusEvent")


@_attrs_define
class VisitorStatusEvent:
    """status — the turn is being retried; not an error yet

    Attributes:
        phase (VisitorStatusEventPhase):
        attempt (int):
    """

    phase: VisitorStatusEventPhase
    attempt: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        phase = self.phase.value

        attempt = self.attempt

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "phase": phase,
                "attempt": attempt,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        phase = VisitorStatusEventPhase(d.pop("phase"))

        attempt = d.pop("attempt")

        visitor_status_event = cls(
            phase=phase,
            attempt=attempt,
        )

        visitor_status_event.additional_properties = d
        return visitor_status_event

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
