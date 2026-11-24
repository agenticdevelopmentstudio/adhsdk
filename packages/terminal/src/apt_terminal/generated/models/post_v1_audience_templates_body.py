from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AudienceTemplatesBody")


@_attrs_define
class PostV1AudienceTemplatesBody:
    """
    Attributes:
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        ecosystem_id (str | Unset):
        kind (str | Unset):
    """

    name: str
    subject: str
    html_body: str
    text_body: str
    ecosystem_id: str | Unset = UNSET
    kind: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        ecosystem_id = self.ecosystem_id

        kind = self.kind

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
                "subject": subject,
                "html_body": html_body,
                "text_body": text_body,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if kind is not UNSET:
            field_dict["kind"] = kind

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("html_body")

        text_body = d.pop("text_body")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        kind = d.pop("kind", UNSET)

        post_v1_audience_templates_body = cls(
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            ecosystem_id=ecosystem_id,
            kind=kind,
        )

        return post_v1_audience_templates_body
