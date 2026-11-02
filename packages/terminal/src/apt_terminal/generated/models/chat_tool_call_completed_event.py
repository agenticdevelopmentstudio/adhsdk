from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="ChatToolCallCompletedEvent")


@_attrs_define
class ChatToolCallCompletedEvent:
    """tool_call_completed — a tool finished

    Attributes:
        name (str):
        ok (bool):
        result (str): JSON-encoded tool result
    """

    name: str
    ok: bool
    result: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        ok = self.ok

        result = self.result

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "ok": ok,
                "result": result,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        ok = d.pop("ok")

        result = d.pop("result")

        chat_tool_call_completed_event = cls(
            name=name,
            ok=ok,
            result=result,
        )

        chat_tool_call_completed_event.additional_properties = d
        return chat_tool_call_completed_event

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
