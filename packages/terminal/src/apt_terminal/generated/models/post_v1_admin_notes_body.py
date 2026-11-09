from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.admin_note_input import AdminNoteInput


T = TypeVar("T", bound="PostV1AdminNotesBody")


@_attrs_define
class PostV1AdminNotesBody:
    """
    Attributes:
        subject_table (str):
        subject_id (str):
        notes (list[AdminNoteInput]): The complete set for this subject. Anything absent is deleted.
        ecosystem (str | Unset): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    subject_table: str
    subject_id: str
    notes: list[AdminNoteInput]
    ecosystem: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_table = self.subject_table

        subject_id = self.subject_id

        notes = []
        for notes_item_data in self.notes:
            notes_item = notes_item_data.to_dict()
            notes.append(notes_item)

        ecosystem = self.ecosystem

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_table": subject_table,
                "subject_id": subject_id,
                "notes": notes,
            }
        )
        if ecosystem is not UNSET:
            field_dict["ecosystem"] = ecosystem

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.admin_note_input import AdminNoteInput

        d = dict(src_dict)
        subject_table = d.pop("subject_table")

        subject_id = d.pop("subject_id")

        notes = []
        _notes = d.pop("notes")
        for notes_item_data in _notes:
            notes_item = AdminNoteInput.from_dict(notes_item_data)

            notes.append(notes_item)

        ecosystem = d.pop("ecosystem", UNSET)

        post_v1_admin_notes_body = cls(
            subject_table=subject_table,
            subject_id=subject_id,
            notes=notes,
            ecosystem=ecosystem,
        )

        post_v1_admin_notes_body.additional_properties = d
        return post_v1_admin_notes_body

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
