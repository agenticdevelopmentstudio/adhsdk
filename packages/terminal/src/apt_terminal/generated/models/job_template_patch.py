from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.job_template_patch_defaults import JobTemplatePatchDefaults
    from ..models.job_template_patch_inputs_item import JobTemplatePatchInputsItem
    from ..models.job_template_patch_steps_item import JobTemplatePatchStepsItem


T = TypeVar("T", bound="JobTemplatePatch")


@_attrs_define
class JobTemplatePatch:
    """
    Attributes:
        name (str | Unset):
        description (None | str | Unset):
        steps (list[JobTemplatePatchStepsItem] | Unset):
        inputs (list[JobTemplatePatchInputsItem] | Unset):
        defaults (JobTemplatePatchDefaults | Unset):
    """

    name: str | Unset = UNSET
    description: None | str | Unset = UNSET
    steps: list[JobTemplatePatchStepsItem] | Unset = UNSET
    inputs: list[JobTemplatePatchInputsItem] | Unset = UNSET
    defaults: JobTemplatePatchDefaults | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        steps: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.steps, Unset):
            steps = []
            for steps_item_data in self.steps:
                steps_item = steps_item_data.to_dict()
                steps.append(steps_item)

        inputs: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.inputs, Unset):
            inputs = []
            for inputs_item_data in self.inputs:
                inputs_item = inputs_item_data.to_dict()
                inputs.append(inputs_item)

        defaults: dict[str, Any] | Unset = UNSET
        if not isinstance(self.defaults, Unset):
            defaults = self.defaults.to_dict()

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if steps is not UNSET:
            field_dict["steps"] = steps
        if inputs is not UNSET:
            field_dict["inputs"] = inputs
        if defaults is not UNSET:
            field_dict["defaults"] = defaults

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_template_patch_defaults import JobTemplatePatchDefaults
        from ..models.job_template_patch_inputs_item import (
            JobTemplatePatchInputsItem,
        )
        from ..models.job_template_patch_steps_item import (
            JobTemplatePatchStepsItem,
        )

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        _steps = d.pop("steps", UNSET)
        steps: list[JobTemplatePatchStepsItem] | Unset = UNSET
        if _steps is not UNSET:
            steps = []
            for steps_item_data in _steps:
                steps_item = JobTemplatePatchStepsItem.from_dict(steps_item_data)

                steps.append(steps_item)

        _inputs = d.pop("inputs", UNSET)
        inputs: list[JobTemplatePatchInputsItem] | Unset = UNSET
        if _inputs is not UNSET:
            inputs = []
            for inputs_item_data in _inputs:
                inputs_item = JobTemplatePatchInputsItem.from_dict(inputs_item_data)

                inputs.append(inputs_item)

        _defaults = d.pop("defaults", UNSET)
        defaults: JobTemplatePatchDefaults | Unset
        if isinstance(_defaults, Unset):
            defaults = UNSET
        else:
            defaults = JobTemplatePatchDefaults.from_dict(_defaults)

        job_template_patch = cls(
            name=name,
            description=description,
            steps=steps,
            inputs=inputs,
            defaults=defaults,
        )

        return job_template_patch
