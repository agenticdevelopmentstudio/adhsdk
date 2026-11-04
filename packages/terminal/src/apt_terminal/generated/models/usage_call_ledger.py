from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.usage_call_event import UsageCallEvent
    from ..models.usage_cost_line import UsageCostLine


T = TypeVar("T", bound="UsageCallLedger")


@_attrs_define
class UsageCallLedger:
    """
    Attributes:
        call_id (UUID):
        events (list[UsageCallEvent]):
        lines (list[UsageCostLine]):
    """

    call_id: UUID
    events: list[UsageCallEvent]
    lines: list[UsageCostLine]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        call_id = str(self.call_id)

        events = []
        for events_item_data in self.events:
            events_item = events_item_data.to_dict()
            events.append(events_item)

        lines = []
        for lines_item_data in self.lines:
            lines_item = lines_item_data.to_dict()
            lines.append(lines_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "callId": call_id,
                "events": events,
                "lines": lines,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_call_event import UsageCallEvent
        from ..models.usage_cost_line import UsageCostLine

        d = dict(src_dict)
        call_id = UUID(d.pop("callId"))

        events = []
        _events = d.pop("events")
        for events_item_data in _events:
            events_item = UsageCallEvent.from_dict(events_item_data)

            events.append(events_item)

        lines = []
        _lines = d.pop("lines")
        for lines_item_data in _lines:
            lines_item = UsageCostLine.from_dict(lines_item_data)

            lines.append(lines_item)

        usage_call_ledger = cls(
            call_id=call_id,
            events=events,
            lines=lines,
        )

        usage_call_ledger.additional_properties = d
        return usage_call_ledger

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
