from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaDemoPreviewChoice")


@_attrs_define
class PersonaDemoPreviewChoice:
    """
    Attributes:
        text (str): The choice's own text, minus its tags
        keywords (list[str]): The words this choice ACTUALLY answers to — resolved from the story, not echoed back from
            the `# match:` tag. A tag written outside the choice's brackets attaches to something else, and this list is
            where that becomes visible.
        off_script (bool): The author tagged this choice `# off_script`
    """

    text: str
    keywords: list[str]
    off_script: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        text = self.text

        keywords = self.keywords

        off_script = self.off_script

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "text": text,
                "keywords": keywords,
                "off_script": off_script,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        text = d.pop("text")

        keywords = cast(list[str], d.pop("keywords"))

        off_script = d.pop("off_script")

        persona_demo_preview_choice = cls(
            text=text,
            keywords=keywords,
            off_script=off_script,
        )

        persona_demo_preview_choice.additional_properties = d
        return persona_demo_preview_choice

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
