from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_persona_user_tool import RegistryPersonaUserTool


T = TypeVar("T", bound="PutAccessPersonasIdUserToolsResponse200")


@_attrs_define
class PutAccessPersonasIdUserToolsResponse200:
    """
    Attributes:
        tools (list[RegistryPersonaUserTool]):
    """

    tools: list[RegistryPersonaUserTool]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tools = []
        for tools_item_data in self.tools:
            tools_item = tools_item_data.to_dict()
            tools.append(tools_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tools": tools,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_persona_user_tool import RegistryPersonaUserTool

        d = dict(src_dict)
        tools = []
        _tools = d.pop("tools")
        for tools_item_data in _tools:
            tools_item = RegistryPersonaUserTool.from_dict(tools_item_data)

            tools.append(tools_item)

        put_access_personas_id_user_tools_response_200 = cls(
            tools=tools,
        )

        put_access_personas_id_user_tools_response_200.additional_properties = d
        return put_access_personas_id_user_tools_response_200

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
