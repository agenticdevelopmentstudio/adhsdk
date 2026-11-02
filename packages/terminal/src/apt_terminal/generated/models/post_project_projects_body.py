from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectProjectsBody")


@_attrs_define
class PostProjectProjectsBody:
    """
    Attributes:
        name (str):
        description (str | Unset):
        color (str | Unset):
        ecosystem_id (str | Unset): the owning ecosystem; defaulted to the caller ecosystem when omitted. A non-admin
            passing a foreign owner is rejected by RLS.
    """

    name: str
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        color = self.color

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        ecosystem_id = d.pop("ecosystemId", UNSET)

        post_project_projects_body = cls(
            name=name,
            description=description,
            color=color,
            ecosystem_id=ecosystem_id,
        )

        post_project_projects_body.additional_properties = d
        return post_project_projects_body

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
