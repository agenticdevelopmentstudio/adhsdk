from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_template_version_defaults import JobTemplateVersionDefaults
    from ..models.job_template_version_inputs_item import JobTemplateVersionInputsItem
    from ..models.job_template_version_steps_item import JobTemplateVersionStepsItem


T = TypeVar("T", bound="JobTemplateVersion")


@_attrs_define
class JobTemplateVersion:
    """
    Attributes:
        template_id (UUID):
        version (int):
        steps (list[JobTemplateVersionStepsItem]):
        inputs (list[JobTemplateVersionInputsItem]):
        defaults (JobTemplateVersionDefaults):
        has_script (bool):
        published_by (str):
        published_at (datetime.datetime):
    """

    template_id: UUID
    version: int
    steps: list[JobTemplateVersionStepsItem]
    inputs: list[JobTemplateVersionInputsItem]
    defaults: JobTemplateVersionDefaults
    has_script: bool
    published_by: str
    published_at: datetime.datetime
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        template_id = str(self.template_id)

        version = self.version

        steps = []
        for steps_item_data in self.steps:
            steps_item = steps_item_data.to_dict()
            steps.append(steps_item)

        inputs = []
        for inputs_item_data in self.inputs:
            inputs_item = inputs_item_data.to_dict()
            inputs.append(inputs_item)

        defaults = self.defaults.to_dict()

        has_script = self.has_script

        published_by = self.published_by

        published_at = self.published_at.isoformat()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "template_id": template_id,
                "version": version,
                "steps": steps,
                "inputs": inputs,
                "defaults": defaults,
                "has_script": has_script,
                "published_by": published_by,
                "published_at": published_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_template_version_defaults import (
            JobTemplateVersionDefaults,
        )
        from ..models.job_template_version_inputs_item import (
            JobTemplateVersionInputsItem,
        )
        from ..models.job_template_version_steps_item import (
            JobTemplateVersionStepsItem,
        )

        d = dict(src_dict)
        template_id = UUID(d.pop("template_id"))

        version = d.pop("version")

        steps = []
        _steps = d.pop("steps")
        for steps_item_data in _steps:
            steps_item = JobTemplateVersionStepsItem.from_dict(steps_item_data)

            steps.append(steps_item)

        inputs = []
        _inputs = d.pop("inputs")
        for inputs_item_data in _inputs:
            inputs_item = JobTemplateVersionInputsItem.from_dict(inputs_item_data)

            inputs.append(inputs_item)

        defaults = JobTemplateVersionDefaults.from_dict(d.pop("defaults"))

        has_script = d.pop("has_script")

        published_by = d.pop("published_by")

        published_at = datetime.datetime.fromisoformat(d.pop("published_at"))

        job_template_version = cls(
            template_id=template_id,
            version=version,
            steps=steps,
            inputs=inputs,
            defaults=defaults,
            has_script=has_script,
            published_by=published_by,
            published_at=published_at,
        )

        job_template_version.additional_properties = d
        return job_template_version

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
