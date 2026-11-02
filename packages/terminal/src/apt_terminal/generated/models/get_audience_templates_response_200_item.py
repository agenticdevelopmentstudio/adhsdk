from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetAudienceTemplatesResponse200Item")


@_attrs_define
class GetAudienceTemplatesResponse200Item:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        created_by (None | str):
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        kind (str):
        is_deleted (bool):
        created_at (str):
        updated_at (str):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    created_by: None | str
    name: str
    subject: str
    html_body: str
    text_body: str
    kind: str
    is_deleted: bool
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        created_by: None | str
        created_by = self.created_by

        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        kind = self.kind

        is_deleted = self.is_deleted

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "createdBy": created_by,
                "name": name,
                "subject": subject,
                "htmlBody": html_body,
                "textBody": text_body,
                "kind": kind,
                "isDeleted": is_deleted,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("createdBy"))

        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("htmlBody")

        text_body = d.pop("textBody")

        kind = d.pop("kind")

        is_deleted = d.pop("isDeleted")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        get_audience_templates_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            created_by=created_by,
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            kind=kind,
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
        )

        return get_audience_templates_response_200_item
