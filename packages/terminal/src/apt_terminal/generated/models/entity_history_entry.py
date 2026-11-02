from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.entity_history_entry_detail_type_0 import EntityHistoryEntryDetailType0


T = TypeVar("T", bound="EntityHistoryEntry")


@_attrs_define
class EntityHistoryEntry:
    """One thing that happened to a row. Append-only; nothing here is editable.

    Attributes:
        id (str):
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):
        actor_id (None | str):
        actor_label (None | str):
        action (str): Free text, not an enum — each subsystem names its own. Emitted today: request_received,
            invite_sent, note_added, status_changed, accepted, notes_updated.
        detail (EntityHistoryEntryDetailType0 | None): Action-specific payload; the shape is whatever emitted the entry.
        created_at (str):
    """

    id: str
    ecosystem_id: str
    subject_table: str
    subject_id: str
    actor_id: None | str
    actor_label: None | str
    action: str
    detail: EntityHistoryEntryDetailType0 | None
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.entity_history_entry_detail_type_0 import (
            EntityHistoryEntryDetailType0,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        subject_table = self.subject_table

        subject_id = self.subject_id

        actor_id: None | str
        actor_id = self.actor_id

        actor_label: None | str
        actor_label = self.actor_label

        action = self.action

        detail: dict[str, Any] | None
        if isinstance(self.detail, EntityHistoryEntryDetailType0):
            detail = self.detail.to_dict()
        else:
            detail = self.detail

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "subjectTable": subject_table,
                "subjectId": subject_id,
                "actorId": actor_id,
                "actorLabel": actor_label,
                "action": action,
                "detail": detail,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.entity_history_entry_detail_type_0 import (
            EntityHistoryEntryDetailType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        subject_table = d.pop("subjectTable")

        subject_id = d.pop("subjectId")

        def _parse_actor_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_id = _parse_actor_id(d.pop("actorId"))

        def _parse_actor_label(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_label = _parse_actor_label(d.pop("actorLabel"))

        action = d.pop("action")

        def _parse_detail(data: object) -> EntityHistoryEntryDetailType0 | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                detail_type_0 = EntityHistoryEntryDetailType0.from_dict(data)

                return detail_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(EntityHistoryEntryDetailType0 | None, data)

        detail = _parse_detail(d.pop("detail"))

        created_at = d.pop("createdAt")

        entity_history_entry = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            subject_table=subject_table,
            subject_id=subject_id,
            actor_id=actor_id,
            actor_label=actor_label,
            action=action,
            detail=detail,
            created_at=created_at,
        )

        entity_history_entry.additional_properties = d
        return entity_history_entry

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
