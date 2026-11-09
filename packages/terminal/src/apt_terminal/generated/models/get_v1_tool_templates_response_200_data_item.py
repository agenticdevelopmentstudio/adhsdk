from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ToolTemplatesResponse200DataItem")


@_attrs_define
class GetV1ToolTemplatesResponse200DataItem:
    """
    Attributes:
        id (str):
        tool_key (str):
        source_kind (str):
        display_name (str):
        description (str):
        read_only (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['tool_template'] | Unset):
    """

    id: str
    tool_key: str
    source_kind: str
    display_name: str
    description: str
    read_only: bool
    created: int
    updated: int
    object_: Literal["tool_template"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        tool_key = self.tool_key

        source_kind = self.source_kind

        display_name = self.display_name

        description = self.description

        read_only = self.read_only

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "tool_key": tool_key,
                "source_kind": source_kind,
                "display_name": display_name,
                "description": description,
                "read_only": read_only,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        tool_key = d.pop("tool_key")

        source_kind = d.pop("source_kind")

        display_name = d.pop("display_name")

        description = d.pop("description")

        read_only = d.pop("read_only")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["tool_template"] | Unset, d.pop("object", UNSET))
        if object_ != "tool_template" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'tool_template', got '{object_}'")

        get_v1_tool_templates_response_200_data_item = cls(
            id=id,
            tool_key=tool_key,
            source_kind=source_kind,
            display_name=display_name,
            description=description,
            read_only=read_only,
            created=created,
            updated=updated,
            object_=object_,
        )

        return get_v1_tool_templates_response_200_data_item
