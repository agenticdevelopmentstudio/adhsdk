from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AdminNote")


@_attrs_define
class AdminNote:
    """An operator note attached to some other row. Never visible to that row’s subject.

    Attributes:
        id (str):
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):
        content (str):
        created_by (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: str
    ecosystem_id: str
    subject_table: str
    subject_id: str
    content: str
    created_by: str
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        subject_table = self.subject_table

        subject_id = self.subject_id

        content = self.content

        created_by = self.created_by

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "subject_table": subject_table,
                "subject_id": subject_id,
                "content": content,
                "created_by": created_by,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        subject_table = d.pop("subject_table")

        subject_id = d.pop("subject_id")

        content = d.pop("content")

        created_by = d.pop("created_by")

        created = d.pop("created")

        updated = d.pop("updated")

        admin_note = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            subject_table=subject_table,
            subject_id=subject_id,
            content=content,
            created_by=created_by,
            created=created,
            updated=updated,
        )

        admin_note.additional_properties = d
        return admin_note

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
