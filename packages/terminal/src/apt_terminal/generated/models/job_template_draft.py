from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_template_draft_defaults import JobTemplateDraftDefaults
    from ..models.job_template_draft_inputs_item import JobTemplateDraftInputsItem
    from ..models.job_template_draft_steps_item import JobTemplateDraftStepsItem


T = TypeVar("T", bound="JobTemplateDraft")


@_attrs_define
class JobTemplateDraft:
    """
    Attributes:
        steps (list[JobTemplateDraftStepsItem]): The steps being edited; each is `{ id, kind, ... }` with kind ai,
            action, webhook, notify, wait or script. Checked in full at publish.
        inputs (list[JobTemplateDraftInputsItem]): Declared inputs: `{ key, label, type, required?, choices? }`.
        defaults (JobTemplateDraftDefaults): Default options: priority, onError, notify, minIntervalMinutes.
    """

    steps: list[JobTemplateDraftStepsItem]
    inputs: list[JobTemplateDraftInputsItem]
    defaults: JobTemplateDraftDefaults
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        steps = []
        for steps_item_data in self.steps:
            steps_item = steps_item_data.to_dict()
            steps.append(steps_item)

        inputs = []
        for inputs_item_data in self.inputs:
            inputs_item = inputs_item_data.to_dict()
            inputs.append(inputs_item)

        defaults = self.defaults.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "steps": steps,
                "inputs": inputs,
                "defaults": defaults,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_template_draft_defaults import JobTemplateDraftDefaults
        from ..models.job_template_draft_inputs_item import (
            JobTemplateDraftInputsItem,
        )
        from ..models.job_template_draft_steps_item import (
            JobTemplateDraftStepsItem,
        )

        d = dict(src_dict)
        steps = []
        _steps = d.pop("steps")
        for steps_item_data in _steps:
            steps_item = JobTemplateDraftStepsItem.from_dict(steps_item_data)

            steps.append(steps_item)

        inputs = []
        _inputs = d.pop("inputs")
        for inputs_item_data in _inputs:
            inputs_item = JobTemplateDraftInputsItem.from_dict(inputs_item_data)

            inputs.append(inputs_item)

        defaults = JobTemplateDraftDefaults.from_dict(d.pop("defaults"))

        job_template_draft = cls(
            steps=steps,
            inputs=inputs,
            defaults=defaults,
        )

        job_template_draft.additional_properties = d
        return job_template_draft

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
