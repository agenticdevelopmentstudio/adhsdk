from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetPersonaToolTemplatesIdResponse200")


@_attrs_define
class GetPersonaToolTemplatesIdResponse200:
    """
    Attributes:
        id (str):
        tool_key (str):
        source_kind (str):
        display_name (str):
        description (str):
        read_only (bool):
        created_at (str):
        updated_at (str):
    """

    id: str
    tool_key: str
    source_kind: str
    display_name: str
    description: str
    read_only: bool
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        tool_key = self.tool_key

        source_kind = self.source_kind

        display_name = self.display_name

        description = self.description

        read_only = self.read_only

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "toolKey": tool_key,
                "sourceKind": source_kind,
                "displayName": display_name,
                "description": description,
                "readOnly": read_only,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        tool_key = d.pop("toolKey")

        source_kind = d.pop("sourceKind")

        display_name = d.pop("displayName")

        description = d.pop("description")

        read_only = d.pop("readOnly")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        get_persona_tool_templates_id_response_200 = cls(
            id=id,
            tool_key=tool_key,
            source_kind=source_kind,
            display_name=display_name,
            description=description,
            read_only=read_only,
            created_at=created_at,
            updated_at=updated_at,
        )

        return get_persona_tool_templates_id_response_200
