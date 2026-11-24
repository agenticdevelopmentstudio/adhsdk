from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_inbound_fired_status import JobInboundFiredStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="JobInboundFired")


@_attrs_define
class JobInboundFired:
    """
    Attributes:
        run_id (str): The run the fire started.
        status (JobInboundFiredStatus | Unset): Present only when the run was written `failed` at once (see
            `errorCode`).
        error_code (str | Unset): Why the run failed at start, e.g. `template_missing`.
    """

    run_id: str
    status: JobInboundFiredStatus | Unset = UNSET
    error_code: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        run_id = self.run_id

        status: str | Unset = UNSET
        if not isinstance(self.status, Unset):
            status = self.status.value

        error_code = self.error_code

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "run_id": run_id,
            }
        )
        if status is not UNSET:
            field_dict["status"] = status
        if error_code is not UNSET:
            field_dict["error_code"] = error_code

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        run_id = d.pop("run_id")

        _status = d.pop("status", UNSET)
        status: JobInboundFiredStatus | Unset
        if isinstance(_status, Unset):
            status = UNSET
        else:
            status = JobInboundFiredStatus(_status)

        error_code = d.pop("error_code", UNSET)

        job_inbound_fired = cls(
            run_id=run_id,
            status=status,
            error_code=error_code,
        )

        job_inbound_fired.additional_properties = d
        return job_inbound_fired

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
