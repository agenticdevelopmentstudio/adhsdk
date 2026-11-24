from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.work_item_assignee_kind_type_1 import WorkItemAssigneeKindType1
from ..models.work_item_assignee_kind_type_2_type_1 import WorkItemAssigneeKindType2Type1
from ..models.work_item_assignee_kind_type_3_type_1 import WorkItemAssigneeKindType3Type1
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1WorkItemsResponse201")


@_attrs_define
class PostV1WorkItemsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        title (str):
        description (str):
        status_id (str): the board column this card sits in
        priority (int): rank, 0 (none) to 4 (urgent); higher is more urgent
        labels (list[str]): the card's labels, from the owner's shared tag vocabulary (the same one research documents
            draw on), in authored order
        rank (str): board order within the project — an opaque key that sorts ascending by BYTE, so a client compares
            two cards with `<` and never parses one. Set only by the server (a create appends; POST /project/work-
            items/{id}/move reorders), so there is no way — and no need — to send one.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        assignee_kind (None | Unset | WorkItemAssigneeKindType1 | WorkItemAssigneeKindType2Type1 |
            WorkItemAssigneeKindType3Type1):
        assignee_id (None | str | Unset):
        start_date (None | str | Unset): date (YYYY-MM-DD)
        due_date (None | str | Unset): date (YYYY-MM-DD)
        parent_id (None | str | Unset): a parent work item in the same project
        iteration_id (None | str | Unset): the time-box this card is committed to; null is the BACKLOG — a real state,
            not an absence. The iteration belongs to the project OWNER, not the project, so a workspace can run one cycle
            across several boards.
        milestone_id (None | str | Unset): the milestone this card counts toward; null = it counts toward none. UNLIKE
            `iterationId` — which names a time-box the project's OWNER holds — this must be a milestone of the card's OWN
            project (400 otherwise): a milestone is a point in one plan, and a card counts toward the plan of the board it
            sits on.
        estimate (int | None | Unset): the card's size, in whatever unit the project's `estimateScale` names. A non-
            negative integer; null is UNESTIMATED, which is distinct from 0 (estimated as trivial).
        triaged_at (None | str | Unset): when this card was ACCEPTED onto the board. null = it is sitting in the triage
            inbox and the board’s list omits it (GET /project/projects/{id}/work-items?includeUntriaged=true shows it
            anyway). Every card created without `triage: true` is accepted at creation, so a board that never used an intake
            queue has none of these. Server-set: POST /project/work-items/{id}/triage stamps it once and nothing un-stamps
            it.
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        object_ (Literal['work_item'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    title: str
    description: str
    status_id: str
    priority: int
    labels: list[str]
    rank: str
    created: int
    updated: int
    is_deleted: bool
    assignee_kind: (
        None
        | Unset
        | WorkItemAssigneeKindType1
        | WorkItemAssigneeKindType2Type1
        | WorkItemAssigneeKindType3Type1
    ) = UNSET
    assignee_id: None | str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    due_date: None | str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    iteration_id: None | str | Unset = UNSET
    milestone_id: None | str | Unset = UNSET
    estimate: int | None | Unset = UNSET
    triaged_at: None | str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    object_: Literal["work_item"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        title = self.title

        description = self.description

        status_id = self.status_id

        priority = self.priority

        labels = self.labels

        rank = self.rank

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        assignee_kind: None | str | Unset
        if isinstance(self.assignee_kind, Unset):
            assignee_kind = UNSET
        elif (
            isinstance(self.assignee_kind, WorkItemAssigneeKindType1)
            or isinstance(self.assignee_kind, WorkItemAssigneeKindType2Type1)
            or isinstance(self.assignee_kind, WorkItemAssigneeKindType3Type1)
        ):
            assignee_kind = self.assignee_kind.value
        else:
            assignee_kind = self.assignee_kind

        assignee_id: None | str | Unset
        if isinstance(self.assignee_id, Unset):
            assignee_id = UNSET
        else:
            assignee_id = self.assignee_id

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

        triaged_at: None | str | Unset
        if isinstance(self.triaged_at, Unset):
            triaged_at = UNSET
        else:
            triaged_at = self.triaged_at

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "title": title,
                "description": description,
                "status_id": status_id,
                "priority": priority,
                "labels": labels,
                "rank": rank,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
            }
        )
        if assignee_kind is not UNSET:
            field_dict["assignee_kind"] = assignee_kind
        if assignee_id is not UNSET:
            field_dict["assignee_id"] = assignee_id
        if start_date is not UNSET:
            field_dict["start_date"] = start_date
        if due_date is not UNSET:
            field_dict["due_date"] = due_date
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if iteration_id is not UNSET:
            field_dict["iteration_id"] = iteration_id
        if milestone_id is not UNSET:
            field_dict["milestone_id"] = milestone_id
        if estimate is not UNSET:
            field_dict["estimate"] = estimate
        if triaged_at is not UNSET:
            field_dict["triaged_at"] = triaged_at
        if created_by is not UNSET:
            field_dict["created_by"] = created_by
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        title = d.pop("title")

        description = d.pop("description")

        status_id = d.pop("status_id")

        priority = d.pop("priority")

        labels = cast(list[str], d.pop("labels"))

        rank = d.pop("rank")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        def _parse_assignee_kind(
            data: object,
        ) -> (
            None
            | Unset
            | WorkItemAssigneeKindType1
            | WorkItemAssigneeKindType2Type1
            | WorkItemAssigneeKindType3Type1
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                assignee_kind_type_1 = WorkItemAssigneeKindType1(data)

                return assignee_kind_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                assignee_kind_type_2_type_1 = WorkItemAssigneeKindType2Type1(data)

                return assignee_kind_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                assignee_kind_type_3_type_1 = WorkItemAssigneeKindType3Type1(data)

                return assignee_kind_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                None
                | Unset
                | WorkItemAssigneeKindType1
                | WorkItemAssigneeKindType2Type1
                | WorkItemAssigneeKindType3Type1,
                data,
            )

        assignee_kind = _parse_assignee_kind(d.pop("assignee_kind", UNSET))

        def _parse_assignee_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        assignee_id = _parse_assignee_id(d.pop("assignee_id", UNSET))

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

        def _parse_triaged_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        triaged_at = _parse_triaged_at(d.pop("triaged_at", UNSET))

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("created_by", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["work_item"] | Unset, d.pop("object", UNSET))
        if object_ != "work_item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'work_item', got '{object_}'")

        post_v1_work_items_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            title=title,
            description=description,
            status_id=status_id,
            priority=priority,
            labels=labels,
            rank=rank,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            assignee_kind=assignee_kind,
            assignee_id=assignee_id,
            start_date=start_date,
            due_date=due_date,
            parent_id=parent_id,
            iteration_id=iteration_id,
            milestone_id=milestone_id,
            estimate=estimate,
            triaged_at=triaged_at,
            created_by=created_by,
            deleted_at=deleted_at,
            object_=object_,
        )

        post_v1_work_items_response_201.additional_properties = d
        return post_v1_work_items_response_201

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
