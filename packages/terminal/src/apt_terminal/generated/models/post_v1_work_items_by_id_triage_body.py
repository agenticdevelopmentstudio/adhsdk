from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_work_items_by_id_triage_body_assignee_kind import (
    PostV1WorkItemsByIdTriageBodyAssigneeKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1WorkItemsByIdTriageBody")


@_attrs_define
class PostV1WorkItemsByIdTriageBody:
    """Accepting a card out of the inbox, with the placement carried in the same request. Every key is optional — accepting
    a card that is already where it belongs is the common case — and each is applied through the same writer a PATCH
    uses, so it validates and records identically. There is no `decline`: declining is naming a status in the `canceled`
    category, which leaves the card findable in a column that says what happened to it.

        Attributes:
            status_id (str | Unset):
            assignee_kind (PostV1WorkItemsByIdTriageBodyAssigneeKind | Unset):
            assignee_id (str | Unset):
            milestone_id (str | Unset):
            iteration_id (str | Unset):
            priority (int | Unset): rank, 0 (none) to 4 (urgent); higher is more urgent
            estimate (int | Unset):
    """

    status_id: str | Unset = UNSET
    assignee_kind: PostV1WorkItemsByIdTriageBodyAssigneeKind | Unset = UNSET
    assignee_id: str | Unset = UNSET
    milestone_id: str | Unset = UNSET
    iteration_id: str | Unset = UNSET
    priority: int | Unset = UNSET
    estimate: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        status_id = self.status_id

        assignee_kind: str | Unset = UNSET
        if not isinstance(self.assignee_kind, Unset):
            assignee_kind = self.assignee_kind.value

        assignee_id = self.assignee_id

        milestone_id = self.milestone_id

        iteration_id = self.iteration_id

        priority = self.priority

        estimate = self.estimate

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if status_id is not UNSET:
            field_dict["status_id"] = status_id
        if assignee_kind is not UNSET:
            field_dict["assignee_kind"] = assignee_kind
        if assignee_id is not UNSET:
            field_dict["assignee_id"] = assignee_id
        if milestone_id is not UNSET:
            field_dict["milestone_id"] = milestone_id
        if iteration_id is not UNSET:
            field_dict["iteration_id"] = iteration_id
        if priority is not UNSET:
            field_dict["priority"] = priority
        if estimate is not UNSET:
            field_dict["estimate"] = estimate

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        status_id = d.pop("status_id", UNSET)

        _assignee_kind = d.pop("assignee_kind", UNSET)
        assignee_kind: PostV1WorkItemsByIdTriageBodyAssigneeKind | Unset
        if isinstance(_assignee_kind, Unset):
            assignee_kind = UNSET
        else:
            assignee_kind = PostV1WorkItemsByIdTriageBodyAssigneeKind(_assignee_kind)

        assignee_id = d.pop("assignee_id", UNSET)

        milestone_id = d.pop("milestone_id", UNSET)

        iteration_id = d.pop("iteration_id", UNSET)

        priority = d.pop("priority", UNSET)

        estimate = d.pop("estimate", UNSET)

        post_v1_work_items_by_id_triage_body = cls(
            status_id=status_id,
            assignee_kind=assignee_kind,
            assignee_id=assignee_id,
            milestone_id=milestone_id,
            iteration_id=iteration_id,
            priority=priority,
            estimate=estimate,
        )

        post_v1_work_items_by_id_triage_body.additional_properties = d
        return post_v1_work_items_by_id_triage_body

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
