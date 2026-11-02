from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchProjectProjectsIdMilestonesMilestoneIdBody")


@_attrs_define
class PatchProjectProjectsIdMilestonesMilestoneIdBody:
    """At least one field is required (a no-op patch is a 400). A null targetDate un-dates it.

    Attributes:
        name (str | Unset):
        description (str | Unset):
        target_date (None | str | Unset):
    """

    name: str | Unset = UNSET
    description: str | Unset = UNSET
    target_date: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        target_date: None | str | Unset
        if isinstance(self.target_date, Unset):
            target_date = UNSET
        else:
            target_date = self.target_date

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if target_date is not UNSET:
            field_dict["targetDate"] = target_date

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        def _parse_target_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        target_date = _parse_target_date(d.pop("targetDate", UNSET))

        patch_project_projects_id_milestones_milestone_id_body = cls(
            name=name,
            description=description,
            target_date=target_date,
        )

        patch_project_projects_id_milestones_milestone_id_body.additional_properties = d
        return patch_project_projects_id_milestones_milestone_id_body

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
