from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AdminNotesResponse200DataItem")


@_attrs_define
class GetV1AdminNotesResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):
        content (str):
        created_by (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['admin_note'] | Unset):
    """

    id: str
    ecosystem_id: str
    subject_table: str
    subject_id: str
    content: str
    created_by: str
    created: int
    updated: int
    object_: Literal["admin_note"] | Unset = UNSET
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

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["admin_note"] | Unset, d.pop("object", UNSET))
        if object_ != "admin_note" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'admin_note', got '{object_}'")

        get_v1_admin_notes_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            subject_table=subject_table,
            subject_id=subject_id,
            content=content,
            created_by=created_by,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_admin_notes_response_200_data_item.additional_properties = d
        return get_v1_admin_notes_response_200_data_item

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
