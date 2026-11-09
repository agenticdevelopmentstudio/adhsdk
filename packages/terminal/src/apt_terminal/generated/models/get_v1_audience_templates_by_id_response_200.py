from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AudienceTemplatesByIdResponse200")


@_attrs_define
class GetV1AudienceTemplatesByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        created_by (None | str):
        author_kind (None | str):
        author_id (None | str):
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        kind (str):
        is_deleted (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['audience.template'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    created_by: None | str
    author_kind: None | str
    author_id: None | str
    name: str
    subject: str
    html_body: str
    text_body: str
    kind: str
    is_deleted: bool
    created: int
    updated: int
    object_: Literal["audience.template"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        created_by: None | str
        created_by = self.created_by

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        kind = self.kind

        is_deleted = self.is_deleted

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "created_by": created_by,
                "author_kind": author_kind,
                "author_id": author_id,
                "name": name,
                "subject": subject,
                "html_body": html_body,
                "text_body": text_body,
                "kind": kind,
                "is_deleted": is_deleted,
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

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("created_by"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("html_body")

        text_body = d.pop("text_body")

        kind = d.pop("kind")

        is_deleted = d.pop("is_deleted")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["audience.template"] | Unset, d.pop("object", UNSET))
        if object_ != "audience.template" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'audience.template', got '{object_}'")

        get_v1_audience_templates_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            created_by=created_by,
            author_kind=author_kind,
            author_id=author_id,
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            kind=kind,
            is_deleted=is_deleted,
            created=created,
            updated=updated,
            object_=object_,
        )

        return get_v1_audience_templates_by_id_response_200
