from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectTemplatesIdWorkItemsBody")


@_attrs_define
class PostProjectTemplatesIdWorkItemsBody:
    """Where the card LANDS — the board-local half a template body deliberately does not carry.

    Attributes:
        project_id (str): the board to build on; the caller needs projects C (subitem) there
        title (str | Unset): overrides the body’s title for THIS card only. The children are never re-titled — renaming
            a checklist’s steps at instantiation is editing the template, not using it.
        status_id (str | Unset): a status of this project; omitted uses the lowest-position column
        milestone_id (str | Unset): a live milestone of THIS project (400 otherwise)
        iteration_id (str | Unset): a live iteration of this project's OWNER (400 otherwise)
    """

    project_id: str
    title: str | Unset = UNSET
    status_id: str | Unset = UNSET
    milestone_id: str | Unset = UNSET
    iteration_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        project_id = self.project_id

        title = self.title

        status_id = self.status_id

        milestone_id = self.milestone_id

        iteration_id = self.iteration_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "projectId": project_id,
            }
        )
        if title is not UNSET:
            field_dict["title"] = title
        if status_id is not UNSET:
            field_dict["statusId"] = status_id
        if milestone_id is not UNSET:
            field_dict["milestoneId"] = milestone_id
        if iteration_id is not UNSET:
            field_dict["iterationId"] = iteration_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        project_id = d.pop("projectId")

        title = d.pop("title", UNSET)

        status_id = d.pop("statusId", UNSET)

        milestone_id = d.pop("milestoneId", UNSET)

        iteration_id = d.pop("iterationId", UNSET)

        post_project_templates_id_work_items_body = cls(
            project_id=project_id,
            title=title,
            status_id=status_id,
            milestone_id=milestone_id,
            iteration_id=iteration_id,
        )

        post_project_templates_id_work_items_body.additional_properties = d
        return post_project_templates_id_work_items_body

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
