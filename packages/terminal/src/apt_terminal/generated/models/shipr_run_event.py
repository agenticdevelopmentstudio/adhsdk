from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.shipr_run_event_stream import ShiprRunEventStream
from ..types import UNSET, Unset

T = TypeVar("T", bound="ShiprRunEvent")


@_attrs_define
class ShiprRunEvent:
    """One line of a run’s log. `seq` is per-run and monotone — use it as a cursor.

    Attributes:
        seq (int | Unset):
        step_id (None | str | Unset):
        stream (ShiprRunEventStream | Unset):
        text (str | Unset):
        at (str | Unset):
    """

    seq: int | Unset = UNSET
    step_id: None | str | Unset = UNSET
    stream: ShiprRunEventStream | Unset = UNSET
    text: str | Unset = UNSET
    at: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        seq = self.seq

        step_id: None | str | Unset
        if isinstance(self.step_id, Unset):
            step_id = UNSET
        else:
            step_id = self.step_id

        stream: str | Unset = UNSET
        if not isinstance(self.stream, Unset):
            stream = self.stream.value

        text = self.text

        at = self.at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if seq is not UNSET:
            field_dict["seq"] = seq
        if step_id is not UNSET:
            field_dict["step_id"] = step_id
        if stream is not UNSET:
            field_dict["stream"] = stream
        if text is not UNSET:
            field_dict["text"] = text
        if at is not UNSET:
            field_dict["at"] = at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        seq = d.pop("seq", UNSET)

        def _parse_step_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        step_id = _parse_step_id(d.pop("step_id", UNSET))

        _stream = d.pop("stream", UNSET)
        stream: ShiprRunEventStream | Unset
        if isinstance(_stream, Unset):
            stream = UNSET
        else:
            stream = ShiprRunEventStream(_stream)

        text = d.pop("text", UNSET)

        at = d.pop("at", UNSET)

        shipr_run_event = cls(
            seq=seq,
            step_id=step_id,
            stream=stream,
            text=text,
            at=at,
        )

        shipr_run_event.additional_properties = d
        return shipr_run_event

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
