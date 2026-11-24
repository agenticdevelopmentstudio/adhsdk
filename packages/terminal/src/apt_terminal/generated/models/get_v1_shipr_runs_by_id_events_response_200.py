from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_run_event import ShiprRunEvent


T = TypeVar("T", bound="GetV1ShiprRunsByIdEventsResponse200")


@_attrs_define
class GetV1ShiprRunsByIdEventsResponse200:
    """
    Attributes:
        events (list[ShiprRunEvent]):
        next_seq (int):
        object_ (Literal['event'] | Unset):
        state (str | Unset):
        done (bool | Unset): The run has settled and there will never be more lines.
    """

    events: list[ShiprRunEvent]
    next_seq: int
    object_: Literal["event"] | Unset = UNSET
    state: str | Unset = UNSET
    done: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        events = []
        for events_item_data in self.events:
            events_item = events_item_data.to_dict()
            events.append(events_item)

        next_seq = self.next_seq

        object_ = self.object_

        state = self.state

        done = self.done

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "events": events,
                "next_seq": next_seq,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if state is not UNSET:
            field_dict["state"] = state
        if done is not UNSET:
            field_dict["done"] = done

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_run_event import ShiprRunEvent

        d = dict(src_dict)
        events = []
        _events = d.pop("events")
        for events_item_data in _events:
            events_item = ShiprRunEvent.from_dict(events_item_data)

            events.append(events_item)

        next_seq = d.pop("next_seq")

        object_ = cast(Literal["event"] | Unset, d.pop("object", UNSET))
        if object_ != "event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'event', got '{object_}'")

        state = d.pop("state", UNSET)

        done = d.pop("done", UNSET)

        get_v1_shipr_runs_by_id_events_response_200 = cls(
            events=events,
            next_seq=next_seq,
            object_=object_,
            state=state,
            done=done,
        )

        get_v1_shipr_runs_by_id_events_response_200.additional_properties = d
        return get_v1_shipr_runs_by_id_events_response_200

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
