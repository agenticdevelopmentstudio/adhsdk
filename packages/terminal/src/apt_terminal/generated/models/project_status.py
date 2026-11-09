from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_status_category import ProjectStatusCategory

T = TypeVar("T", bound="ProjectStatus")


@_attrs_define
class ProjectStatus:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        key (str): stable identifier, unique within the project
        label (str):
        category (ProjectStatusCategory):
        position (int): column order (ascending)
        created (int): Unix timestamp, in seconds.
    """

    id: str
    ecosystem_id: str
    project_id: str
    key: str
    label: str
    category: ProjectStatusCategory
    position: int
    created: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        key = self.key

        label = self.label

        category = self.category.value

        position = self.position

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "key": key,
                "label": label,
                "category": category,
                "position": position,
                "created": created,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        key = d.pop("key")

        label = d.pop("label")

        category = ProjectStatusCategory(d.pop("category"))

        position = d.pop("position")

        created = d.pop("created")

        project_status = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            key=key,
            label=label,
            category=category,
            position=position,
            created=created,
        )

        project_status.additional_properties = d
        return project_status

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
