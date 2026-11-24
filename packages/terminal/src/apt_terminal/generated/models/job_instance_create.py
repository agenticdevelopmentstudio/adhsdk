from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.job_instance_create_inputs import JobInstanceCreateInputs
    from ..models.job_instance_create_options import JobInstanceCreateOptions
    from ..models.job_instance_create_steps_item import JobInstanceCreateStepsItem


T = TypeVar("T", bound="JobInstanceCreate")


@_attrs_define
class JobInstanceCreate:
    """
    Attributes:
        name (str):
        template_id (UUID | Unset): Exactly one of templateId and steps.
        template_version (int | Unset): Defaults to the latest. A customer may only name the offered (latest) version.
        steps (list[JobInstanceCreateStepsItem] | Unset): Inline steps: not for an end-customer token (403
            `inline_steps_not_allowed`).
        inputs (JobInstanceCreateInputs | Unset):
        environment_id (None | Unset | UUID):
        options (JobInstanceCreateOptions | Unset): Job options: priority (0 to 90), the default error strategy, and
            notify.
    """

    name: str
    template_id: UUID | Unset = UNSET
    template_version: int | Unset = UNSET
    steps: list[JobInstanceCreateStepsItem] | Unset = UNSET
    inputs: JobInstanceCreateInputs | Unset = UNSET
    environment_id: None | Unset | UUID = UNSET
    options: JobInstanceCreateOptions | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        template_id: str | Unset = UNSET
        if not isinstance(self.template_id, Unset):
            template_id = str(self.template_id)

        template_version = self.template_version

        steps: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.steps, Unset):
            steps = []
            for steps_item_data in self.steps:
                steps_item = steps_item_data.to_dict()
                steps.append(steps_item)

        inputs: dict[str, Any] | Unset = UNSET
        if not isinstance(self.inputs, Unset):
            inputs = self.inputs.to_dict()

        environment_id: None | str | Unset
        if isinstance(self.environment_id, Unset):
            environment_id = UNSET
        elif isinstance(self.environment_id, UUID):
            environment_id = str(self.environment_id)
        else:
            environment_id = self.environment_id

        options: dict[str, Any] | Unset = UNSET
        if not isinstance(self.options, Unset):
            options = self.options.to_dict()

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
            }
        )
        if template_id is not UNSET:
            field_dict["template_id"] = template_id
        if template_version is not UNSET:
            field_dict["template_version"] = template_version
        if steps is not UNSET:
            field_dict["steps"] = steps
        if inputs is not UNSET:
            field_dict["inputs"] = inputs
        if environment_id is not UNSET:
            field_dict["environment_id"] = environment_id
        if options is not UNSET:
            field_dict["options"] = options

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_instance_create_inputs import JobInstanceCreateInputs
        from ..models.job_instance_create_options import JobInstanceCreateOptions
        from ..models.job_instance_create_steps_item import (
            JobInstanceCreateStepsItem,
        )

        d = dict(src_dict)
        name = d.pop("name")

        _template_id = d.pop("template_id", UNSET)
        template_id: UUID | Unset
        if isinstance(_template_id, Unset):
            template_id = UNSET
        else:
            template_id = UUID(_template_id)

        template_version = d.pop("template_version", UNSET)

        _steps = d.pop("steps", UNSET)
        steps: list[JobInstanceCreateStepsItem] | Unset = UNSET
        if _steps is not UNSET:
            steps = []
            for steps_item_data in _steps:
                steps_item = JobInstanceCreateStepsItem.from_dict(steps_item_data)

                steps.append(steps_item)

        _inputs = d.pop("inputs", UNSET)
        inputs: JobInstanceCreateInputs | Unset
        if isinstance(_inputs, Unset):
            inputs = UNSET
        else:
            inputs = JobInstanceCreateInputs.from_dict(_inputs)

        def _parse_environment_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                environment_id_type_0 = UUID(data)

                return environment_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        environment_id = _parse_environment_id(d.pop("environment_id", UNSET))

        _options = d.pop("options", UNSET)
        options: JobInstanceCreateOptions | Unset
        if isinstance(_options, Unset):
            options = UNSET
        else:
            options = JobInstanceCreateOptions.from_dict(_options)

        job_instance_create = cls(
            name=name,
            template_id=template_id,
            template_version=template_version,
            steps=steps,
            inputs=inputs,
            environment_id=environment_id,
            options=options,
        )

        return job_instance_create
