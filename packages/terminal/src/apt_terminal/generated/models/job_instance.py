from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_instance_owner_kind import JobInstanceOwnerKind
from ..models.job_instance_status import JobInstanceStatus

if TYPE_CHECKING:
    from ..models.job_instance_inputs import JobInstanceInputs
    from ..models.job_instance_options import JobInstanceOptions
    from ..models.job_instance_steps_type_0_item import JobInstanceStepsType0Item


T = TypeVar("T", bound="JobInstance")


@_attrs_define
class JobInstance:
    """
    Attributes:
        id (UUID):
        name (str):
        owner_kind (JobInstanceOwnerKind):
        owner_id (str):
        template_id (None | UUID):
        template_version (int | None):
        steps (list[JobInstanceStepsType0Item] | None): A job's own inline steps; null for a job made from a template.
        inputs (JobInstanceInputs):
        environment_id (None | UUID):
        options (JobInstanceOptions): Job options: priority (0 to 90), the default error strategy, and notify.
        status (JobInstanceStatus):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: UUID
    name: str
    owner_kind: JobInstanceOwnerKind
    owner_id: str
    template_id: None | UUID
    template_version: int | None
    steps: list[JobInstanceStepsType0Item] | None
    inputs: JobInstanceInputs
    environment_id: None | UUID
    options: JobInstanceOptions
    status: JobInstanceStatus
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        name = self.name

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        template_id: None | str
        if isinstance(self.template_id, UUID):
            template_id = str(self.template_id)
        else:
            template_id = self.template_id

        template_version: int | None
        template_version = self.template_version

        steps: list[dict[str, Any]] | None
        if isinstance(self.steps, list):
            steps = []
            for steps_type_0_item_data in self.steps:
                steps_type_0_item = steps_type_0_item_data.to_dict()
                steps.append(steps_type_0_item)

        else:
            steps = self.steps

        inputs = self.inputs.to_dict()

        environment_id: None | str
        if isinstance(self.environment_id, UUID):
            environment_id = str(self.environment_id)
        else:
            environment_id = self.environment_id

        options = self.options.to_dict()

        status = self.status.value

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "template_id": template_id,
                "template_version": template_version,
                "steps": steps,
                "inputs": inputs,
                "environment_id": environment_id,
                "options": options,
                "status": status,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_instance_inputs import JobInstanceInputs
        from ..models.job_instance_options import JobInstanceOptions
        from ..models.job_instance_steps_type_0_item import (
            JobInstanceStepsType0Item,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        name = d.pop("name")

        owner_kind = JobInstanceOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

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

        def _parse_steps(data: object) -> list[JobInstanceStepsType0Item] | None:
            if data is None:
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                steps_type_0 = []
                _steps_type_0 = data
                for steps_type_0_item_data in _steps_type_0:
                    steps_type_0_item = JobInstanceStepsType0Item.from_dict(steps_type_0_item_data)

                    steps_type_0.append(steps_type_0_item)

                return steps_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[JobInstanceStepsType0Item] | None, data)

        steps = _parse_steps(d.pop("steps"))

        inputs = JobInstanceInputs.from_dict(d.pop("inputs"))

        def _parse_environment_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                environment_id_type_0 = UUID(data)

                return environment_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        environment_id = _parse_environment_id(d.pop("environment_id"))

        options = JobInstanceOptions.from_dict(d.pop("options"))

        status = JobInstanceStatus(d.pop("status"))

        created = d.pop("created")

        updated = d.pop("updated")

        job_instance = cls(
            id=id,
            name=name,
            owner_kind=owner_kind,
            owner_id=owner_id,
            template_id=template_id,
            template_version=template_version,
            steps=steps,
            inputs=inputs,
            environment_id=environment_id,
            options=options,
            status=status,
            created=created,
            updated=updated,
        )

        job_instance.additional_properties = d
        return job_instance

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
