from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..models.project_template_body_statuses_item_category import (
    ProjectTemplateBodyStatusesItemCategory,
)

T = TypeVar("T", bound="ProjectTemplateBodyStatusesItem")


@_attrs_define
class ProjectTemplateBodyStatusesItem:
    """
    Attributes:
        key (str):
        label (str):
        category (ProjectTemplateBodyStatusesItemCategory):
    """

    key: str
    label: str
    category: ProjectTemplateBodyStatusesItemCategory

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        category = self.category.value

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "key": key,
                "label": label,
                "category": category,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        category = ProjectTemplateBodyStatusesItemCategory(d.pop("category"))

        project_template_body_statuses_item = cls(
            key=key,
            label=label,
            category=category,
        )

        return project_template_body_statuses_item
