from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_demo_preview_diagnostic_severity import PersonaDemoPreviewDiagnosticSeverity

T = TypeVar("T", bound="PersonaDemoPreviewDiagnostic")


@_attrs_define
class PersonaDemoPreviewDiagnostic:
    """
    Attributes:
        severity (PersonaDemoPreviewDiagnosticSeverity):
        line (int | None): 1-based source line, if the compiler gave one
        message (str):
    """

    severity: PersonaDemoPreviewDiagnosticSeverity
    line: int | None
    message: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        severity = self.severity.value

        line: int | None
        line = self.line

        message = self.message

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "severity": severity,
                "line": line,
                "message": message,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        severity = PersonaDemoPreviewDiagnosticSeverity(d.pop("severity"))

        def _parse_line(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        line = _parse_line(d.pop("line"))

        message = d.pop("message")

        persona_demo_preview_diagnostic = cls(
            severity=severity,
            line=line,
            message=message,
        )

        persona_demo_preview_diagnostic.additional_properties = d
        return persona_demo_preview_diagnostic

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
