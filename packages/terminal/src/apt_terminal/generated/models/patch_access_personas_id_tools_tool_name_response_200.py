from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_persona_tool_grant import RegistryPersonaToolGrant


T = TypeVar("T", bound="PatchAccessPersonasIdToolsToolNameResponse200")


@_attrs_define
class PatchAccessPersonasIdToolsToolNameResponse200:
    """
    Attributes:
        tool (RegistryPersonaToolGrant):
    """

    tool: RegistryPersonaToolGrant
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tool = self.tool.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tool": tool,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_persona_tool_grant import RegistryPersonaToolGrant

        d = dict(src_dict)
        tool = RegistryPersonaToolGrant.from_dict(d.pop("tool"))

        patch_access_personas_id_tools_tool_name_response_200 = cls(
            tool=tool,
        )

        patch_access_personas_id_tools_tool_name_response_200.additional_properties = d
        return patch_access_personas_id_tools_tool_name_response_200

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
