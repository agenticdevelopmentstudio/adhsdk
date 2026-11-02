from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PutAccessPersonasIdUserToolsBody")


@_attrs_define
class PutAccessPersonasIdUserToolsBody:
    """
    Attributes:
        allowed (list[str]): the tools the caller allows the persona to invoke for them; every name must be one of the
            persona's owner-granted tools (400 otherwise). [] clears; all names = all-on.
    """

    allowed: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        allowed = self.allowed

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "allowed": allowed,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        allowed = cast(list[str], d.pop("allowed"))

        put_access_personas_id_user_tools_body = cls(
            allowed=allowed,
        )

        put_access_personas_id_user_tools_body.additional_properties = d
        return put_access_personas_id_user_tools_body

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
