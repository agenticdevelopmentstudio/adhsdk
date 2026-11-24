from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..models.job_instance_patch_status import JobInstancePatchStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.job_instance_patch_inputs import JobInstancePatchInputs
    from ..models.job_instance_patch_options import JobInstancePatchOptions


T = TypeVar("T", bound="JobInstancePatch")


@_attrs_define
class JobInstancePatch:
    """
    Attributes:
        name (str | Unset):
        inputs (JobInstancePatchInputs | Unset):
        environment_id (None | Unset | UUID):
        options (JobInstancePatchOptions | Unset): Job options: priority (0 to 90), the default error strategy, and
            notify.
        status (JobInstancePatchStatus | Unset):
    """

    name: str | Unset = UNSET
    inputs: JobInstancePatchInputs | Unset = UNSET
    environment_id: None | Unset | UUID = UNSET
    options: JobInstancePatchOptions | Unset = UNSET
    status: JobInstancePatchStatus | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

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

        status: str | Unset = UNSET
        if not isinstance(self.status, Unset):
            status = self.status.value

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if inputs is not UNSET:
            field_dict["inputs"] = inputs
        if environment_id is not UNSET:
            field_dict["environment_id"] = environment_id
        if options is not UNSET:
            field_dict["options"] = options
        if status is not UNSET:
            field_dict["status"] = status

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_instance_patch_inputs import JobInstancePatchInputs
        from ..models.job_instance_patch_options import JobInstancePatchOptions

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        _inputs = d.pop("inputs", UNSET)
        inputs: JobInstancePatchInputs | Unset
        if isinstance(_inputs, Unset):
            inputs = UNSET
        else:
            inputs = JobInstancePatchInputs.from_dict(_inputs)

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
        options: JobInstancePatchOptions | Unset
        if isinstance(_options, Unset):
            options = UNSET
        else:
            options = JobInstancePatchOptions.from_dict(_options)

        _status = d.pop("status", UNSET)
        status: JobInstancePatchStatus | Unset
        if isinstance(_status, Unset):
            status = UNSET
        else:
            status = JobInstancePatchStatus(_status)

        job_instance_patch = cls(
            name=name,
            inputs=inputs,
            environment_id=environment_id,
            options=options,
            status=status,
        )

        return job_instance_patch
