from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="RegistryPersonaToolCatalogItem")


@_attrs_define
class RegistryPersonaToolCatalogItem:
    """
    Attributes:
        tool_name (str):
        source (None | str): null for curated internal tools; else the source id (e.g. "web", "mcp.<server>")
        display_name (str): human-readable label from the tool catalog (persona.tool_templates); falls back to toolName
            when no catalog row exists
        description (str): human-readable description from the tool catalog; '' when no catalog row exists
        read_only (bool):
        granted (bool): true iff this persona currently holds the tool
        autonomous (bool): true = this grant skips the approval gate (except acting as self, which always gates); false
            when not granted
    """

    tool_name: str
    source: None | str
    display_name: str
    description: str
    read_only: bool
    granted: bool
    autonomous: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tool_name = self.tool_name

        source: None | str
        source = self.source

        display_name = self.display_name

        description = self.description

        read_only = self.read_only

        granted = self.granted

        autonomous = self.autonomous

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "toolName": tool_name,
                "source": source,
                "displayName": display_name,
                "description": description,
                "readOnly": read_only,
                "granted": granted,
                "autonomous": autonomous,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tool_name = d.pop("toolName")

        def _parse_source(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        source = _parse_source(d.pop("source"))

        display_name = d.pop("displayName")

        description = d.pop("description")

        read_only = d.pop("readOnly")

        granted = d.pop("granted")

        autonomous = d.pop("autonomous")

        registry_persona_tool_catalog_item = cls(
            tool_name=tool_name,
            source=source,
            display_name=display_name,
            description=description,
            read_only=read_only,
            granted=granted,
            autonomous=autonomous,
        )

        registry_persona_tool_catalog_item.additional_properties = d
        return registry_persona_tool_catalog_item

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
