from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1PersonasByIdUserToolsResponse200DataItem")


@_attrs_define
class GetV1PersonasByIdUserToolsResponse200DataItem:
    """
    Attributes:
        tool_name (str):
        source (None | str): null for curated internal tools; else the source id (e.g. "web", "mcp.<server>")
        display_name (str): human-readable label from the tool catalog (persona.tool_templates); falls back to toolName
            when no catalog row exists
        description (str): human-readable description from the tool catalog; '' when no catalog row exists
        read_only (bool):
        allowed (bool): true iff the calling user has allowed the persona to invoke this tool for them
        object_ (Literal['user_tool'] | Unset):
    """

    tool_name: str
    source: None | str
    display_name: str
    description: str
    read_only: bool
    allowed: bool
    object_: Literal["user_tool"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tool_name = self.tool_name

        source: None | str
        source = self.source

        display_name = self.display_name

        description = self.description

        read_only = self.read_only

        allowed = self.allowed

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tool_name": tool_name,
                "source": source,
                "display_name": display_name,
                "description": description,
                "read_only": read_only,
                "allowed": allowed,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tool_name = d.pop("tool_name")

        def _parse_source(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        source = _parse_source(d.pop("source"))

        display_name = d.pop("display_name")

        description = d.pop("description")

        read_only = d.pop("read_only")

        allowed = d.pop("allowed")

        object_ = cast(Literal["user_tool"] | Unset, d.pop("object", UNSET))
        if object_ != "user_tool" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'user_tool', got '{object_}'")

        get_v1_personas_by_id_user_tools_response_200_data_item = cls(
            tool_name=tool_name,
            source=source,
            display_name=display_name,
            description=description,
            read_only=read_only,
            allowed=allowed,
            object_=object_,
        )

        get_v1_personas_by_id_user_tools_response_200_data_item.additional_properties = d
        return get_v1_personas_by_id_user_tools_response_200_data_item

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
