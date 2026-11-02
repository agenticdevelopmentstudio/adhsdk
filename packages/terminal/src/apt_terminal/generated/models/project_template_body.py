from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define

from ..models.project_template_body_estimate_scale import ProjectTemplateBodyEstimateScale
from ..models.project_template_body_priority_scale import ProjectTemplateBodyPriorityScale
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_template_body_milestones_item import ProjectTemplateBodyMilestonesItem
    from ..models.project_template_body_statuses_item import ProjectTemplateBodyStatusesItem


T = TypeVar("T", bound="ProjectTemplateBody")


@_attrs_define
class ProjectTemplateBody:
    """
    Attributes:
        description (str | Unset):
        color (str | Unset):
        estimate_scale (ProjectTemplateBodyEstimateScale | Unset):
        priority_scale (ProjectTemplateBodyPriorityScale | Unset):
        item_noun (str | Unset):
        item_noun_plural (str | Unset):
        statuses (list[ProjectTemplateBodyStatusesItem] | Unset): the board columns to open with, IN ORDER — the array
            IS the order, so no positions appear here to disagree with the list they sit in. Keys must be unique. Omitted
            opens the board with the usual three columns.
        milestones (list[ProjectTemplateBodyMilestonesItem] | Unset): the plan points to seed, undated. Names must be
            unique.
    """

    description: str | Unset = UNSET
    color: str | Unset = UNSET
    estimate_scale: ProjectTemplateBodyEstimateScale | Unset = UNSET
    priority_scale: ProjectTemplateBodyPriorityScale | Unset = UNSET
    item_noun: str | Unset = UNSET
    item_noun_plural: str | Unset = UNSET
    statuses: list[ProjectTemplateBodyStatusesItem] | Unset = UNSET
    milestones: list[ProjectTemplateBodyMilestonesItem] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        description = self.description

        color = self.color

        estimate_scale: str | Unset = UNSET
        if not isinstance(self.estimate_scale, Unset):
            estimate_scale = self.estimate_scale.value

        priority_scale: str | Unset = UNSET
        if not isinstance(self.priority_scale, Unset):
            priority_scale = self.priority_scale.value

        item_noun = self.item_noun

        item_noun_plural = self.item_noun_plural

        statuses: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.statuses, Unset):
            statuses = []
            for statuses_item_data in self.statuses:
                statuses_item = statuses_item_data.to_dict()
                statuses.append(statuses_item)

        milestones: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.milestones, Unset):
            milestones = []
            for milestones_item_data in self.milestones:
                milestones_item = milestones_item_data.to_dict()
                milestones.append(milestones_item)

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if estimate_scale is not UNSET:
            field_dict["estimateScale"] = estimate_scale
        if priority_scale is not UNSET:
            field_dict["priorityScale"] = priority_scale
        if item_noun is not UNSET:
            field_dict["itemNoun"] = item_noun
        if item_noun_plural is not UNSET:
            field_dict["itemNounPlural"] = item_noun_plural
        if statuses is not UNSET:
            field_dict["statuses"] = statuses
        if milestones is not UNSET:
            field_dict["milestones"] = milestones

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_template_body_milestones_item import (
            ProjectTemplateBodyMilestonesItem,
        )
        from ..models.project_template_body_statuses_item import (
            ProjectTemplateBodyStatusesItem,
        )

        d = dict(src_dict)
        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        _estimate_scale = d.pop("estimateScale", UNSET)
        estimate_scale: ProjectTemplateBodyEstimateScale | Unset
        if isinstance(_estimate_scale, Unset):
            estimate_scale = UNSET
        else:
            estimate_scale = ProjectTemplateBodyEstimateScale(_estimate_scale)

        _priority_scale = d.pop("priorityScale", UNSET)
        priority_scale: ProjectTemplateBodyPriorityScale | Unset
        if isinstance(_priority_scale, Unset):
            priority_scale = UNSET
        else:
            priority_scale = ProjectTemplateBodyPriorityScale(_priority_scale)

        item_noun = d.pop("itemNoun", UNSET)

        item_noun_plural = d.pop("itemNounPlural", UNSET)

        _statuses = d.pop("statuses", UNSET)
        statuses: list[ProjectTemplateBodyStatusesItem] | Unset = UNSET
        if _statuses is not UNSET:
            statuses = []
            for statuses_item_data in _statuses:
                statuses_item = ProjectTemplateBodyStatusesItem.from_dict(statuses_item_data)

                statuses.append(statuses_item)

        _milestones = d.pop("milestones", UNSET)
        milestones: list[ProjectTemplateBodyMilestonesItem] | Unset = UNSET
        if _milestones is not UNSET:
            milestones = []
            for milestones_item_data in _milestones:
                milestones_item = ProjectTemplateBodyMilestonesItem.from_dict(milestones_item_data)

                milestones.append(milestones_item)

        project_template_body = cls(
            description=description,
            color=color,
            estimate_scale=estimate_scale,
            priority_scale=priority_scale,
            item_noun=item_noun,
            item_noun_plural=item_noun_plural,
            statuses=statuses,
            milestones=milestones,
        )

        return project_template_body
