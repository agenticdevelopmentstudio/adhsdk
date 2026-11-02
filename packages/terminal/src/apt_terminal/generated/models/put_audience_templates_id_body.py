from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutAudienceTemplatesIdBody")


@_attrs_define
class PutAudienceTemplatesIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        subject (str | Unset):
        html_body (str | Unset):
        text_body (str | Unset):
        kind (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    subject: str | Unset = UNSET
    html_body: str | Unset = UNSET
    text_body: str | Unset = UNSET
    kind: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        kind = self.kind

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if subject is not UNSET:
            field_dict["subject"] = subject
        if html_body is not UNSET:
            field_dict["htmlBody"] = html_body
        if text_body is not UNSET:
            field_dict["textBody"] = text_body
        if kind is not UNSET:
            field_dict["kind"] = kind

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        name = d.pop("name", UNSET)

        subject = d.pop("subject", UNSET)

        html_body = d.pop("htmlBody", UNSET)

        text_body = d.pop("textBody", UNSET)

        kind = d.pop("kind", UNSET)

        put_audience_templates_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            kind=kind,
        )

        return put_audience_templates_id_body
