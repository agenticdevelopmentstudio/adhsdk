from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentDatesBody")


@_attrs_define
class PostContentDatesBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        label (str | Unset):
        date (str | Unset):
        recurrence (str | Unset):
        contact_id (None | str | Unset):
        notes (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    label: str | Unset = UNSET
    date: str | Unset = UNSET
    recurrence: str | Unset = UNSET
    contact_id: None | str | Unset = UNSET
    notes: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        label = self.label

        date = self.date

        recurrence = self.recurrence

        contact_id: None | str | Unset
        if isinstance(self.contact_id, Unset):
            contact_id = UNSET
        else:
            contact_id = self.contact_id

        notes = self.notes

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if label is not UNSET:
            field_dict["label"] = label
        if date is not UNSET:
            field_dict["date"] = date
        if recurrence is not UNSET:
            field_dict["recurrence"] = recurrence
        if contact_id is not UNSET:
            field_dict["contactId"] = contact_id
        if notes is not UNSET:
            field_dict["notes"] = notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        label = d.pop("label", UNSET)

        date = d.pop("date", UNSET)

        recurrence = d.pop("recurrence", UNSET)

        def _parse_contact_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        contact_id = _parse_contact_id(d.pop("contactId", UNSET))

        notes = d.pop("notes", UNSET)

        post_content_dates_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            label=label,
            date=date,
            recurrence=recurrence,
            contact_id=contact_id,
            notes=notes,
        )

        return post_content_dates_body
