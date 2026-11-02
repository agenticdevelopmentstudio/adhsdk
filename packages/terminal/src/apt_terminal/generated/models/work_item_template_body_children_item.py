from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="WorkItemTemplateBodyChildrenItem")


@_attrs_define
class WorkItemTemplateBodyChildrenItem:
    """
    Attributes:
        title (str):
        description (str | Unset):
        priority (int | Unset): rank, 0 (none) to 4 (urgent); higher is more urgent
        estimate (int | Unset):
        labels (list[str] | Unset):
    """

    title: str
    description: str | Unset = UNSET
    priority: int | Unset = UNSET
    estimate: int | Unset = UNSET
    labels: list[str] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        description = self.description

        priority = self.priority

        estimate = self.estimate

        labels: list[str] | Unset = UNSET
        if not isinstance(self.labels, Unset):
            labels = self.labels

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

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title")

        description = d.pop("description", UNSET)

        priority = d.pop("priority", UNSET)

        estimate = d.pop("estimate", UNSET)

        labels = cast(list[str], d.pop("labels", UNSET))

        work_item_template_body_children_item = cls(
            title=title,
            description=description,
            priority=priority,
            estimate=estimate,
            labels=labels,
        )

        return work_item_template_body_children_item
