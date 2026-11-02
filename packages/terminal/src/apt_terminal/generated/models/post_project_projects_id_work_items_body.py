from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_project_projects_id_work_items_body_assignee_kind import (
    PostProjectProjectsIdWorkItemsBodyAssigneeKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectProjectsIdWorkItemsBody")


@_attrs_define
class PostProjectProjectsIdWorkItemsBody:
    """
    Attributes:
        title (str):
        description (str | Unset):
        status_id (str | Unset): must be a status of this project; defaults to the lowest-position column
        assignee_kind (PostProjectProjectsIdWorkItemsBodyAssigneeKind | Unset):
        assignee_id (str | Unset): set with assigneeKind (both or neither); must be a current participant
        priority (int | Unset): rank, 0 (none) to 4 (urgent); higher is more urgent
        start_date (str | Unset): date (YYYY-MM-DD)
        due_date (str | Unset): date (YYYY-MM-DD)
        labels (list[str] | Unset): labels for the card; each is trimmed, blanks are dropped, and a repeat keeps its
            first position. A label not yet in the owner's vocabulary is created there.
        parent_id (str | Unset): a live work item in the same project (not self)
        iteration_id (str | Unset): a live iteration of this project's OWNER (400 otherwise); omitted leaves the card in
            the backlog
        milestone_id (str | Unset): a live milestone of THIS project (400 otherwise — narrower than the iteration rule
            above, because a milestone is a point in one plan); omitted leaves the card counting toward none
        estimate (int | Unset): the card’s size; omitted leaves it unestimated
        triage (bool | Unset): file this card into the board’s TRIAGE INBOX instead of onto the board (`triagedAt` stays
            null and the board list omits it until someone accepts it). Defaults false, which is what keeps the inbox opt-
            in: an intake form or an integration sets it, and every other caller keeps the behaviour it has always had.
    """

    title: str
    description: str | Unset = UNSET
    status_id: str | Unset = UNSET
    assignee_kind: PostProjectProjectsIdWorkItemsBodyAssigneeKind | Unset = UNSET
    assignee_id: str | Unset = UNSET
    priority: int | Unset = UNSET
    start_date: str | Unset = UNSET
    due_date: str | Unset = UNSET
    labels: list[str] | Unset = UNSET
    parent_id: str | Unset = UNSET
    iteration_id: str | Unset = UNSET
    milestone_id: str | Unset = UNSET
    estimate: int | Unset = UNSET
    triage: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        description = self.description

        status_id = self.status_id

        assignee_kind: str | Unset = UNSET
        if not isinstance(self.assignee_kind, Unset):
            assignee_kind = self.assignee_kind.value

        assignee_id = self.assignee_id

        priority = self.priority

        start_date = self.start_date

        due_date = self.due_date

        labels: list[str] | Unset = UNSET
        if not isinstance(self.labels, Unset):
            labels = self.labels

        parent_id = self.parent_id

        iteration_id = self.iteration_id

        milestone_id = self.milestone_id

        estimate = self.estimate

        triage = self.triage

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "title": title,
            }
        )
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
        if triage is not UNSET:
            field_dict["triage"] = triage

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title")

        description = d.pop("description", UNSET)

        status_id = d.pop("statusId", UNSET)

        _assignee_kind = d.pop("assigneeKind", UNSET)
        assignee_kind: PostProjectProjectsIdWorkItemsBodyAssigneeKind | Unset
        if isinstance(_assignee_kind, Unset):
            assignee_kind = UNSET
        else:
            assignee_kind = PostProjectProjectsIdWorkItemsBodyAssigneeKind(_assignee_kind)

        assignee_id = d.pop("assigneeId", UNSET)

        priority = d.pop("priority", UNSET)

        start_date = d.pop("startDate", UNSET)

        due_date = d.pop("dueDate", UNSET)

        labels = cast(list[str], d.pop("labels", UNSET))

        parent_id = d.pop("parentId", UNSET)

        iteration_id = d.pop("iterationId", UNSET)

        milestone_id = d.pop("milestoneId", UNSET)

        estimate = d.pop("estimate", UNSET)

        triage = d.pop("triage", UNSET)

        post_project_projects_id_work_items_body = cls(
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
            triage=triage,
        )

        post_project_projects_id_work_items_body.additional_properties = d
        return post_project_projects_id_work_items_body

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
