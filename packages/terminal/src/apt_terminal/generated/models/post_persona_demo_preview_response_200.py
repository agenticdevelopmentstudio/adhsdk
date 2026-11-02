from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.persona_demo_preview_choice import PersonaDemoPreviewChoice
    from ..models.persona_demo_preview_diagnostic import PersonaDemoPreviewDiagnostic


T = TypeVar("T", bound="PostPersonaDemoPreviewResponse200")


@_attrs_define
class PostPersonaDemoPreviewResponse200:
    """
    Attributes:
        text (None | str): Null ⇒ the turn ESCALATES: the real model answers and the demo says nothing
        on_script (bool): False ⇒ the message matched no standing choice
        sign_in_line (bool): The reply is the sign-in line, not the script
        budget_exhausted (bool): The story does not terminate
        choices (list[PersonaDemoPreviewChoice]):
        diagnostics (list[PersonaDemoPreviewDiagnostic]):
        tag_placement_hint (str): The one sentence about where `# match:` and `# off_script` go
    """

    text: None | str
    on_script: bool
    sign_in_line: bool
    budget_exhausted: bool
    choices: list[PersonaDemoPreviewChoice]
    diagnostics: list[PersonaDemoPreviewDiagnostic]
    tag_placement_hint: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        text: None | str
        text = self.text

        on_script = self.on_script

        sign_in_line = self.sign_in_line

        budget_exhausted = self.budget_exhausted

        choices = []
        for choices_item_data in self.choices:
            choices_item = choices_item_data.to_dict()
            choices.append(choices_item)

        diagnostics = []
        for diagnostics_item_data in self.diagnostics:
            diagnostics_item = diagnostics_item_data.to_dict()
            diagnostics.append(diagnostics_item)

        tag_placement_hint = self.tag_placement_hint

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "text": text,
                "onScript": on_script,
                "signInLine": sign_in_line,
                "budgetExhausted": budget_exhausted,
                "choices": choices,
                "diagnostics": diagnostics,
                "tagPlacementHint": tag_placement_hint,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_demo_preview_choice import PersonaDemoPreviewChoice
        from ..models.persona_demo_preview_diagnostic import (
            PersonaDemoPreviewDiagnostic,
        )

        d = dict(src_dict)

        def _parse_text(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        text = _parse_text(d.pop("text"))

        on_script = d.pop("onScript")

        sign_in_line = d.pop("signInLine")

        budget_exhausted = d.pop("budgetExhausted")

        choices = []
        _choices = d.pop("choices")
        for choices_item_data in _choices:
            choices_item = PersonaDemoPreviewChoice.from_dict(choices_item_data)

            choices.append(choices_item)

        diagnostics = []
        _diagnostics = d.pop("diagnostics")
        for diagnostics_item_data in _diagnostics:
            diagnostics_item = PersonaDemoPreviewDiagnostic.from_dict(diagnostics_item_data)

            diagnostics.append(diagnostics_item)

        tag_placement_hint = d.pop("tagPlacementHint")

        post_persona_demo_preview_response_200 = cls(
            text=text,
            on_script=on_script,
            sign_in_line=sign_in_line,
            budget_exhausted=budget_exhausted,
            choices=choices,
            diagnostics=diagnostics,
            tag_placement_hint=tag_placement_hint,
        )

        post_persona_demo_preview_response_200.additional_properties = d
        return post_persona_demo_preview_response_200

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
