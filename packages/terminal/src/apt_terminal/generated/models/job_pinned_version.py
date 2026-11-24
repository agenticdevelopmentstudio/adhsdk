from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_pinned_version_defaults import JobPinnedVersionDefaults
    from ..models.job_pinned_version_inputs_item import JobPinnedVersionInputsItem
    from ..models.job_pinned_version_steps_item import JobPinnedVersionStepsItem


T = TypeVar("T", bound="JobPinnedVersion")


@_attrs_define
class JobPinnedVersion:
    """
    Attributes:
        template_id (None | UUID):
        template_version (int | None):
        inputs (list[JobPinnedVersionInputsItem]): Declared inputs: `{ key, label, type, required?, choices? }`; empty
            for inline steps.
        defaults (JobPinnedVersionDefaults):
        steps (list[JobPinnedVersionStepsItem]):
    """

    template_id: None | UUID
    template_version: int | None
    inputs: list[JobPinnedVersionInputsItem]
    defaults: JobPinnedVersionDefaults
    steps: list[JobPinnedVersionStepsItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        template_id: None | str
        if isinstance(self.template_id, UUID):
            template_id = str(self.template_id)
        else:
            template_id = self.template_id

        template_version: int | None
        template_version = self.template_version

        inputs = []
        for inputs_item_data in self.inputs:
            inputs_item = inputs_item_data.to_dict()
            inputs.append(inputs_item)

        defaults = self.defaults.to_dict()

        steps = []
        for steps_item_data in self.steps:
            steps_item = steps_item_data.to_dict()
            steps.append(steps_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "template_id": template_id,
                "template_version": template_version,
                "inputs": inputs,
                "defaults": defaults,
                "steps": steps,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_pinned_version_defaults import JobPinnedVersionDefaults
        from ..models.job_pinned_version_inputs_item import (
            JobPinnedVersionInputsItem,
        )
        from ..models.job_pinned_version_steps_item import (
            JobPinnedVersionStepsItem,
        )

        d = dict(src_dict)

        def _parse_template_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                template_id_type_0 = UUID(data)

                return template_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        template_id = _parse_template_id(d.pop("template_id"))

        def _parse_template_version(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        template_version = _parse_template_version(d.pop("template_version"))

        inputs = []
        _inputs = d.pop("inputs")
        for inputs_item_data in _inputs:
            inputs_item = JobPinnedVersionInputsItem.from_dict(inputs_item_data)

            inputs.append(inputs_item)

        defaults = JobPinnedVersionDefaults.from_dict(d.pop("defaults"))

        steps = []
        _steps = d.pop("steps")
        for steps_item_data in _steps:
            steps_item = JobPinnedVersionStepsItem.from_dict(steps_item_data)

            steps.append(steps_item)

        job_pinned_version = cls(
            template_id=template_id,
            template_version=template_version,
            inputs=inputs,
            defaults=defaults,
            steps=steps,
        )

        job_pinned_version.additional_properties = d
        return job_pinned_version

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
