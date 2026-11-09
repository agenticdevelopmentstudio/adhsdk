from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ToolTemplatesBody")


@_attrs_define
class PostV1ToolTemplatesBody:
    """
    Attributes:
        tool_key (str):
        source_kind (str):
        display_name (str):
        description (str | Unset):
        read_only (bool | Unset):
    """

    tool_key: str
    source_kind: str
    display_name: str
    description: str | Unset = UNSET
    read_only: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        tool_key = self.tool_key

        source_kind = self.source_kind

        display_name = self.display_name

        description = self.description

        read_only = self.read_only

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "tool_key": tool_key,
                "source_kind": source_kind,
                "display_name": display_name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if read_only is not UNSET:
            field_dict["read_only"] = read_only

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tool_key = d.pop("tool_key")

        source_kind = d.pop("source_kind")

        display_name = d.pop("display_name")

        description = d.pop("description", UNSET)

        read_only = d.pop("read_only", UNSET)

        post_v1_tool_templates_body = cls(
            tool_key=tool_key,
            source_kind=source_kind,
            display_name=display_name,
            description=description,
            read_only=read_only,
        )

        return post_v1_tool_templates_body
