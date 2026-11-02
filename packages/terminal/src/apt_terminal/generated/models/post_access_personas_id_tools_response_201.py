from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_persona_tool_catalog_item import RegistryPersonaToolCatalogItem


T = TypeVar("T", bound="PostAccessPersonasIdToolsResponse201")


@_attrs_define
class PostAccessPersonasIdToolsResponse201:
    """
    Attributes:
        tool (RegistryPersonaToolCatalogItem):
    """

    tool: RegistryPersonaToolCatalogItem
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
        from ..models.registry_persona_tool_catalog_item import (
            RegistryPersonaToolCatalogItem,
        )

        d = dict(src_dict)
        tool = RegistryPersonaToolCatalogItem.from_dict(d.pop("tool"))

        post_access_personas_id_tools_response_201 = cls(
            tool=tool,
        )

        post_access_personas_id_tools_response_201.additional_properties = d
        return post_access_personas_id_tools_response_201

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
