from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ShiprReposByIdBody")


@_attrs_define
class PostV1ShiprReposByIdBody:
    """
    Attributes:
        personas (str | Unset): Selects which kind of object this call works on.
    """

    personas: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        personas = self.personas

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if personas is not UNSET:
            field_dict["personas"] = personas

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        personas = d.pop("personas", UNSET)

        post_v1_shipr_repos_by_id_body = cls(
            personas=personas,
        )

        post_v1_shipr_repos_by_id_body.additional_properties = d
        return post_v1_shipr_repos_by_id_body

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
