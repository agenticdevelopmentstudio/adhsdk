from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1PersonasByIdToolsByToolNameResponse200")


@_attrs_define
class PostV1PersonasByIdToolsByToolNameResponse200:
    """
    Attributes:
        tool_name (str):
        autonomous (bool): true = this grant skips the approval gate (except acting as self, which always gates)
        created (int): Unix timestamp, in seconds.
        object_ (Literal['tool'] | Unset):
    """

    tool_name: str
    autonomous: bool
    created: int
    object_: Literal["tool"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tool_name = self.tool_name

        autonomous = self.autonomous

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tool_name": tool_name,
                "autonomous": autonomous,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tool_name = d.pop("tool_name")

        autonomous = d.pop("autonomous")

        created = d.pop("created")

        object_ = cast(Literal["tool"] | Unset, d.pop("object", UNSET))
        if object_ != "tool" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'tool', got '{object_}'")

        post_v1_personas_by_id_tools_by_tool_name_response_200 = cls(
            tool_name=tool_name,
            autonomous=autonomous,
            created=created,
            object_=object_,
        )

        post_v1_personas_by_id_tools_by_tool_name_response_200.additional_properties = d
        return post_v1_personas_by_id_tools_by_tool_name_response_200

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
