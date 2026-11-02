from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.work_item_template_body_children_item import WorkItemTemplateBodyChildrenItem


T = TypeVar("T", bound="WorkItemTemplateBody")


@_attrs_define
class WorkItemTemplateBody:
    """
    Attributes:
        title (str):
        description (str | Unset):
        priority (int | Unset): rank, 0 (none) to 4 (urgent); higher is more urgent
        estimate (int | Unset):
        labels (list[str] | Unset):
        children (list[WorkItemTemplateBodyChildrenItem] | Unset): the sub-tasks that always come with this card — ONE
            level deep, because a body that could nest arbitrarily would be a project template wearing the wrong noun. Each
            child inherits the parent’s column, plan point and cycle at instantiation.
    """

    title: str
    description: str | Unset = UNSET
    priority: int | Unset = UNSET
    estimate: int | Unset = UNSET
    labels: list[str] | Unset = UNSET
    children: list[WorkItemTemplateBodyChildrenItem] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        description = self.description

        priority = self.priority

        estimate = self.estimate

        labels: list[str] | Unset = UNSET
        if not isinstance(self.labels, Unset):
            labels = self.labels

        children: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.children, Unset):
            children = []
            for children_item_data in self.children:
                children_item = children_item_data.to_dict()
                children.append(children_item)

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "title": title,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if priority is not UNSET:
            field_dict["priority"] = priority
        if estimate is not UNSET:
            field_dict["estimate"] = estimate
        if labels is not UNSET:
            field_dict["labels"] = labels
        if children is not UNSET:
            field_dict["children"] = children

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.work_item_template_body_children_item import (
            WorkItemTemplateBodyChildrenItem,
        )

        d = dict(src_dict)
        title = d.pop("title")

        description = d.pop("description", UNSET)

        priority = d.pop("priority", UNSET)

        estimate = d.pop("estimate", UNSET)

        labels = cast(list[str], d.pop("labels", UNSET))

        _children = d.pop("children", UNSET)
        children: list[WorkItemTemplateBodyChildrenItem] | Unset = UNSET
        if _children is not UNSET:
            children = []
            for children_item_data in _children:
                children_item = WorkItemTemplateBodyChildrenItem.from_dict(children_item_data)

                children.append(children_item)

        work_item_template_body = cls(
            title=title,
            description=description,
            priority=priority,
            estimate=estimate,
            labels=labels,
            children=children,
        )

        return work_item_template_body
