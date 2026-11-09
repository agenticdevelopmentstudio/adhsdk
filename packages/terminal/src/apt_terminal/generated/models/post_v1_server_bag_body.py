from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ServerBagBody")


@_attrs_define
class PostV1ServerBagBody:
    """
    Attributes:
        key (str):
        value (Any): Arbitrary JSON value
        description (str | Unset):
        ecosystem (str | Unset): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    key: str
    value: Any
    description: str | Unset = UNSET
    ecosystem: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        value = self.value

        description = self.description

        ecosystem = self.ecosystem

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "value": value,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if ecosystem is not UNSET:
            field_dict["ecosystem"] = ecosystem

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        value = d.pop("value")

        description = d.pop("description", UNSET)

        ecosystem = d.pop("ecosystem", UNSET)

        post_v1_server_bag_body = cls(
            key=key,
            value=value,
            description=description,
            ecosystem=ecosystem,
        )

        post_v1_server_bag_body.additional_properties = d
        return post_v1_server_bag_body

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
