from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaBootstrapTool")


@_attrs_define
class PersonaBootstrapTool:
    """
    Attributes:
        name (str):
        display_name (str):
        read_only (bool):
        autonomous (bool): May be called without a human in the loop
    """

    name: str
    display_name: str
    read_only: bool
    autonomous: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        display_name = self.display_name

        read_only = self.read_only

        autonomous = self.autonomous

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "displayName": display_name,
                "readOnly": read_only,
                "autonomous": autonomous,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        display_name = d.pop("displayName")

        read_only = d.pop("readOnly")

        autonomous = d.pop("autonomous")

        persona_bootstrap_tool = cls(
            name=name,
            display_name=display_name,
            read_only=read_only,
            autonomous=autonomous,
        )

        persona_bootstrap_tool.additional_properties = d
        return persona_bootstrap_tool

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
