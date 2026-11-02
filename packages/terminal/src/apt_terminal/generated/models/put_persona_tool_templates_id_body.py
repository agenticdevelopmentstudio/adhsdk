from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutPersonaToolTemplatesIdBody")


@_attrs_define
class PutPersonaToolTemplatesIdBody:
    """
    Attributes:
        tool_key (str | Unset):
        source_kind (str | Unset):
        display_name (str | Unset):
        description (str | Unset):
        read_only (bool | Unset):
    """

    tool_key: str | Unset = UNSET
    source_kind: str | Unset = UNSET
    display_name: str | Unset = UNSET
    description: str | Unset = UNSET
    read_only: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        tool_key = self.tool_key

        source_kind = self.source_kind

        display_name = self.display_name

        description = self.description

        read_only = self.read_only

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if tool_key is not UNSET:
            field_dict["toolKey"] = tool_key
        if source_kind is not UNSET:
            field_dict["sourceKind"] = source_kind
        if display_name is not UNSET:
            field_dict["displayName"] = display_name
        if description is not UNSET:
            field_dict["description"] = description
        if read_only is not UNSET:
            field_dict["readOnly"] = read_only

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tool_key = d.pop("toolKey", UNSET)

        source_kind = d.pop("sourceKind", UNSET)

        display_name = d.pop("displayName", UNSET)

        description = d.pop("description", UNSET)

        read_only = d.pop("readOnly", UNSET)

        put_persona_tool_templates_id_body = cls(
            tool_key=tool_key,
            source_kind=source_kind,
            display_name=display_name,
            description=description,
            read_only=read_only,
        )

        return put_persona_tool_templates_id_body
