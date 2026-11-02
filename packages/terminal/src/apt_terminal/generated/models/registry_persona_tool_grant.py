from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="RegistryPersonaToolGrant")


@_attrs_define
class RegistryPersonaToolGrant:
    """
    Attributes:
        tool_name (str):
        autonomous (bool): true = this grant skips the approval gate (except acting as self, which always gates)
        created_at (str):
    """

    tool_name: str
    autonomous: bool
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tool_name = self.tool_name

        autonomous = self.autonomous

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "toolName": tool_name,
                "autonomous": autonomous,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tool_name = d.pop("toolName")

        autonomous = d.pop("autonomous")

        created_at = d.pop("createdAt")

        registry_persona_tool_grant = cls(
            tool_name=tool_name,
            autonomous=autonomous,
            created_at=created_at,
        )

        registry_persona_tool_grant.additional_properties = d
        return registry_persona_tool_grant

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
