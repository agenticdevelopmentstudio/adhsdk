from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.entity_history_entry_detail_type_0 import EntityHistoryEntryDetailType0


T = TypeVar("T", bound="GetV1EntityHistoryResponse200DataItem")


@_attrs_define
class GetV1EntityHistoryResponse200DataItem:
    """
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
        created (int): Unix timestamp, in seconds.
        object_ (Literal['entity_history'] | Unset):
    """

    id: str
    ecosystem_id: str
    subject_table: str
    subject_id: str
    actor_id: None | str
    actor_label: None | str
    action: str
    detail: EntityHistoryEntryDetailType0 | None
    created: int
    object_: Literal["entity_history"] | Unset = UNSET
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

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "subject_table": subject_table,
                "subject_id": subject_id,
                "actor_id": actor_id,
                "actor_label": actor_label,
                "action": action,
                "detail": detail,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.entity_history_entry_detail_type_0 import (
            EntityHistoryEntryDetailType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        subject_table = d.pop("subject_table")

        subject_id = d.pop("subject_id")

        def _parse_actor_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_id = _parse_actor_id(d.pop("actor_id"))

        def _parse_actor_label(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_label = _parse_actor_label(d.pop("actor_label"))

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

        created = d.pop("created")

        object_ = cast(Literal["entity_history"] | Unset, d.pop("object", UNSET))
        if object_ != "entity_history" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'entity_history', got '{object_}'")

        get_v1_entity_history_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            subject_table=subject_table,
            subject_id=subject_id,
            actor_id=actor_id,
            actor_label=actor_label,
            action=action,
            detail=detail,
            created=created,
            object_=object_,
        )

        get_v1_entity_history_response_200_data_item.additional_properties = d
        return get_v1_entity_history_response_200_data_item

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
