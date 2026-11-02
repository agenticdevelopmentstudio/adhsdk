from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_project_work_items_id_body_assignee_kind import (
    PatchProjectWorkItemsIdBodyAssigneeKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchProjectWorkItemsIdBody")


@_attrs_define
class PatchProjectWorkItemsIdBody:
    """At least one mutable field is required (a no-op patch is a 400).

    Attributes:
        title (str | Unset):
        description (str | Unset):
        status_id (str | Unset):
        assignee_kind (PatchProjectWorkItemsIdBodyAssigneeKind | Unset): null clears the assignee (with assigneeId)
        assignee_id (None | str | Unset):
        priority (int | Unset): rank, 0 (none) to 4 (urgent); higher is more urgent
        start_date (None | str | Unset):
        due_date (None | str | Unset):
        labels (list[str] | Unset): replaces the card's whole label set (an empty array clears it)
        parent_id (None | str | Unset): null detaches the parent
        iteration_id (None | str | Unset): commits the card to a live iteration of its project's OWNER (400 otherwise);
            null returns it to the backlog
        milestone_id (None | str | Unset): points the card at a live milestone of ITS OWN project (400 otherwise); null
            detaches it from the plan
        estimate (int | None | Unset): null un-estimates the card — distinct from 0, which estimates it as trivial
    """

    title: str | Unset = UNSET
    description: str | Unset = UNSET
    status_id: str | Unset = UNSET
    assignee_kind: PatchProjectWorkItemsIdBodyAssigneeKind | Unset = UNSET
    assignee_id: None | str | Unset = UNSET
    priority: int | Unset = UNSET
    start_date: None | str | Unset = UNSET
    due_date: None | str | Unset = UNSET
    labels: list[str] | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    iteration_id: None | str | Unset = UNSET
    milestone_id: None | str | Unset = UNSET
    estimate: int | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        description = self.description

        status_id = self.status_id

        assignee_kind: str | Unset = UNSET
        if not isinstance(self.assignee_kind, Unset):
            assignee_kind = self.assignee_kind.value

        assignee_id: None | str | Unset
        if isinstance(self.assignee_id, Unset):
            assignee_id = UNSET
        else:
            assignee_id = self.assignee_id

        priority = self.priority

        start_date: None | str | Unset
        if isinstance(self.start_date, Unset):
            start_date = UNSET
        else:
            start_date = self.start_date

        due_date: None | str | Unset
        if isinstance(self.due_date, Unset):
            due_date = UNSET
        else:
            due_date = self.due_date

        labels: list[str] | Unset = UNSET
        if not isinstance(self.labels, Unset):
            labels = self.labels

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        iteration_id: None | str | Unset
        if isinstance(self.iteration_id, Unset):
            iteration_id = UNSET
        else:
            iteration_id = self.iteration_id

        milestone_id: None | str | Unset
        if isinstance(self.milestone_id, Unset):
            milestone_id = UNSET
        else:
            milestone_id = self.milestone_id

        estimate: int | None | Unset
        if isinstance(self.estimate, Unset):
            estimate = UNSET
        else:
            estimate = self.estimate

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if title is not UNSET:
            field_dict["title"] = title
        if description is not UNSET:
            field_dict["description"] = description
        if status_id is not UNSET:
            field_dict["statusId"] = status_id
        if assignee_kind is not UNSET:
            field_dict["assigneeKind"] = assignee_kind
        if assignee_id is not UNSET:
            field_dict["assigneeId"] = assignee_id
        if priority is not UNSET:
            field_dict["priority"] = priority
        if start_date is not UNSET:
            field_dict["startDate"] = start_date
        if due_date is not UNSET:
            field_dict["dueDate"] = due_date
        if labels is not UNSET:
            field_dict["labels"] = labels
        if parent_id is not UNSET:
            field_dict["parentId"] = parent_id
        if iteration_id is not UNSET:
            field_dict["iterationId"] = iteration_id
        if milestone_id is not UNSET:
            field_dict["milestoneId"] = milestone_id
        if estimate is not UNSET:
            field_dict["estimate"] = estimate

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title", UNSET)

        description = d.pop("description", UNSET)

        status_id = d.pop("statusId", UNSET)

        _assignee_kind = d.pop("assigneeKind", UNSET)
        assignee_kind: PatchProjectWorkItemsIdBodyAssigneeKind | Unset
        if isinstance(_assignee_kind, Unset):
            assignee_kind = UNSET
        else:
            assignee_kind = PatchProjectWorkItemsIdBodyAssigneeKind(_assignee_kind)

        def _parse_assignee_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        assignee_id = _parse_assignee_id(d.pop("assigneeId", UNSET))

        priority = d.pop("priority", UNSET)

        def _parse_start_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_date = _parse_start_date(d.pop("startDate", UNSET))

        def _parse_due_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        due_date = _parse_due_date(d.pop("dueDate", UNSET))

        labels = cast(list[str], d.pop("labels", UNSET))

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parentId", UNSET))

        def _parse_iteration_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        iteration_id = _parse_iteration_id(d.pop("iterationId", UNSET))

        def _parse_milestone_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        milestone_id = _parse_milestone_id(d.pop("milestoneId", UNSET))

        def _parse_estimate(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        estimate = _parse_estimate(d.pop("estimate", UNSET))

        patch_project_work_items_id_body = cls(
            title=title,
            description=description,
            status_id=status_id,
            assignee_kind=assignee_kind,
            assignee_id=assignee_id,
            priority=priority,
            start_date=start_date,
            due_date=due_date,
            labels=labels,
            parent_id=parent_id,
            iteration_id=iteration_id,
            milestone_id=milestone_id,
            estimate=estimate,
        )

        patch_project_work_items_id_body.additional_properties = d
        return patch_project_work_items_id_body

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
