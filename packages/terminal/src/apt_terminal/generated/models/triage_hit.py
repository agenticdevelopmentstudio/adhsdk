from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.triage_hit_priority_scale import TriageHitPriorityScale
from ..types import UNSET, Unset

T = TypeVar("T", bound="TriageHit")


@_attrs_define
class TriageHit:
    """
    Attributes:
        id (str):
        project_id (str):
        project_name (str): the OWNING board’s name — a queue spanning boards is undecidable without it, and the client
            cannot join it itself.
        item_key (str): the rendered key (`ADH-42`)
        title (str):
        description (str):
        status_id (str): the column the card was FILED into. It is not a decision anyone has made yet — that is
            precisely what triage withholds — but an intake form that files by category has already said something worth
            showing.
        priority (int): rank, 0 (none) to 4 (urgent); higher is more urgent
        priority_scale (TriageHitPriorityScale): whether the OWNING board ranks its work — 'none' means show no priority
            for this row. Carried per row for the same reason projectName is: the queue spans boards, so the client has no
            single project to read it off. The board's item NOUN is deliberately absent: a queue mixing recipes and stories
            has no single word for what it holds.
        created_at (str): when it arrived; the queue is ordered by this, oldest first
        item_number (int | Unset):
        created_by (None | str | Unset):
    """

    id: str
    project_id: str
    project_name: str
    item_key: str
    title: str
    description: str
    status_id: str
    priority: int
    priority_scale: TriageHitPriorityScale
    created_at: str
    item_number: int | Unset = UNSET
    created_by: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        project_id = self.project_id

        project_name = self.project_name

        item_key = self.item_key

        title = self.title

        description = self.description

        status_id = self.status_id

        priority = self.priority

        priority_scale = self.priority_scale.value

        created_at = self.created_at

        item_number = self.item_number

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "projectId": project_id,
                "projectName": project_name,
                "itemKey": item_key,
                "title": title,
                "description": description,
                "statusId": status_id,
                "priority": priority,
                "priorityScale": priority_scale,
                "createdAt": created_at,
            }
        )
        if item_number is not UNSET:
            field_dict["itemNumber"] = item_number
        if created_by is not UNSET:
            field_dict["createdBy"] = created_by

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        project_id = d.pop("projectId")

        project_name = d.pop("projectName")

        item_key = d.pop("itemKey")

        title = d.pop("title")

        description = d.pop("description")

        status_id = d.pop("statusId")

        priority = d.pop("priority")

        priority_scale = TriageHitPriorityScale(d.pop("priorityScale"))

        created_at = d.pop("createdAt")

        item_number = d.pop("itemNumber", UNSET)

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("createdBy", UNSET))

        triage_hit = cls(
            id=id,
            project_id=project_id,
            project_name=project_name,
            item_key=item_key,
            title=title,
            description=description,
            status_id=status_id,
            priority=priority,
            priority_scale=priority_scale,
            created_at=created_at,
            item_number=item_number,
            created_by=created_by,
        )

        triage_hit.additional_properties = d
        return triage_hit

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
