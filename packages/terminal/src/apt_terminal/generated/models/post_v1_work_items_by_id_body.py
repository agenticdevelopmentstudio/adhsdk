from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_work_items_by_id_body_assignee_kind import PostV1WorkItemsByIdBodyAssigneeKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_work_items_by_id_body_fields import PostV1WorkItemsByIdBodyFields


T = TypeVar("T", bound="PostV1WorkItemsByIdBody")


@_attrs_define
class PostV1WorkItemsByIdBody:
    """
    Attributes:
        title (str | Unset):
        description (str | Unset):
        status_id (str | Unset):
        assignee_kind (PostV1WorkItemsByIdBodyAssigneeKind | Unset): null clears the assignee (with assigneeId)
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
        fields (PostV1WorkItemsByIdBodyFields | Unset): Updates `fields`.
    """

    title: str | Unset = UNSET
    description: str | Unset = UNSET
    status_id: str | Unset = UNSET
    assignee_kind: PostV1WorkItemsByIdBodyAssigneeKind | Unset = UNSET
    assignee_id: None | str | Unset = UNSET
    priority: int | Unset = UNSET
    start_date: None | str | Unset = UNSET
    due_date: None | str | Unset = UNSET
    labels: list[str] | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    iteration_id: None | str | Unset = UNSET
    milestone_id: None | str | Unset = UNSET
    estimate: int | None | Unset = UNSET
    fields: PostV1WorkItemsByIdBodyFields | Unset = UNSET
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

        fields: dict[str, Any] | Unset = UNSET
        if not isinstance(self.fields, Unset):
            fields = self.fields.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if title is not UNSET:
            field_dict["title"] = title
        if description is not UNSET:
            field_dict["description"] = description
        if status_id is not UNSET:
            field_dict["status_id"] = status_id
        if assignee_kind is not UNSET:
            field_dict["assignee_kind"] = assignee_kind
        if assignee_id is not UNSET:
            field_dict["assignee_id"] = assignee_id
        if priority is not UNSET:
            field_dict["priority"] = priority
        if start_date is not UNSET:
            field_dict["start_date"] = start_date
        if due_date is not UNSET:
            field_dict["due_date"] = due_date
        if labels is not UNSET:
            field_dict["labels"] = labels
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if iteration_id is not UNSET:
            field_dict["iteration_id"] = iteration_id
        if milestone_id is not UNSET:
            field_dict["milestone_id"] = milestone_id
        if estimate is not UNSET:
            field_dict["estimate"] = estimate
        if fields is not UNSET:
            field_dict["fields"] = fields

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_work_items_by_id_body_fields import (
            PostV1WorkItemsByIdBodyFields,
        )

        d = dict(src_dict)
        title = d.pop("title", UNSET)

        description = d.pop("description", UNSET)

        status_id = d.pop("status_id", UNSET)

        _assignee_kind = d.pop("assignee_kind", UNSET)
        assignee_kind: PostV1WorkItemsByIdBodyAssigneeKind | Unset
        if isinstance(_assignee_kind, Unset):
            assignee_kind = UNSET
        else:
            assignee_kind = PostV1WorkItemsByIdBodyAssigneeKind(_assignee_kind)

        def _parse_assignee_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        assignee_id = _parse_assignee_id(d.pop("assignee_id", UNSET))

        priority = d.pop("priority", UNSET)

        def _parse_start_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_date = _parse_start_date(d.pop("start_date", UNSET))

        def _parse_due_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        due_date = _parse_due_date(d.pop("due_date", UNSET))

        labels = cast(list[str], d.pop("labels", UNSET))

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parent_id", UNSET))

        def _parse_iteration_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        iteration_id = _parse_iteration_id(d.pop("iteration_id", UNSET))

        def _parse_milestone_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        milestone_id = _parse_milestone_id(d.pop("milestone_id", UNSET))

        def _parse_estimate(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        estimate = _parse_estimate(d.pop("estimate", UNSET))

        _fields = d.pop("fields", UNSET)
        fields: PostV1WorkItemsByIdBodyFields | Unset
        if isinstance(_fields, Unset):
            fields = UNSET
        else:
            fields = PostV1WorkItemsByIdBodyFields.from_dict(_fields)

        post_v1_work_items_by_id_body = cls(
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
            fields=fields,
        )

        post_v1_work_items_by_id_body.additional_properties = d
        return post_v1_work_items_by_id_body

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
