from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.project import Project
    from ..models.project_milestone import ProjectMilestone


T = TypeVar("T", bound="PostProjectTemplatesIdProjectsResponse201")


@_attrs_define
class PostProjectTemplatesIdProjectsResponse201:
    """
    Attributes:
        project (Project):
        milestones (list[ProjectMilestone]):
    """

    project: Project
    milestones: list[ProjectMilestone]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        project = self.project.to_dict()

        milestones = []
        for milestones_item_data in self.milestones:
            milestones_item = milestones_item_data.to_dict()
            milestones.append(milestones_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "project": project,
                "milestones": milestones,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project import Project
        from ..models.project_milestone import ProjectMilestone

        d = dict(src_dict)
        project = Project.from_dict(d.pop("project"))

        milestones = []
        _milestones = d.pop("milestones")
        for milestones_item_data in _milestones:
            milestones_item = ProjectMilestone.from_dict(milestones_item_data)

            milestones.append(milestones_item)

        post_project_templates_id_projects_response_201 = cls(
            project=project,
            milestones=milestones,
        )

        post_project_templates_id_projects_response_201.additional_properties = d
        return post_project_templates_id_projects_response_201

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
