from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegistriesByIdSectionsBySectionIdBody")


@_attrs_define
class PostV1RegistriesByIdSectionsBySectionIdBody:
    """
    Attributes:
        label (str | Unset):
        description (str | Unset):
        sort_order (int | Unset):
    """

    label: str | Unset = UNSET
    description: str | Unset = UNSET
    sort_order: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        label = self.label

        description = self.description

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if label is not UNSET:
            field_dict["label"] = label
        if description is not UNSET:
            field_dict["description"] = description
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        label = d.pop("label", UNSET)

        description = d.pop("description", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_registries_by_id_sections_by_section_id_body = cls(
            label=label,
            description=description,
            sort_order=sort_order,
        )

        post_v1_registries_by_id_sections_by_section_id_body.additional_properties = d
        return post_v1_registries_by_id_sections_by_section_id_body

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
