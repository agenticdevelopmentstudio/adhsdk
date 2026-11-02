from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="TemplateAvailableViaType0")


@_attrs_define
class TemplateAvailableViaType0:
    """Set ⇒ informational template: no first-party API; connect via the named templates.

    Attributes:
        note (str):
        templates (list[str]):
    """

    note: str
    templates: list[str]

    def to_dict(self) -> dict[str, Any]:
        note = self.note

        templates = self.templates

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "note": note,
                "templates": templates,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        note = d.pop("note")

        templates = cast(list[str], d.pop("templates"))

        template_available_via_type_0 = cls(
            note=note,
            templates=templates,
        )

        return template_available_via_type_0
