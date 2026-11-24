from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_run_started_status import JobRunStartedStatus

T = TypeVar("T", bound="JobRunStarted")


@_attrs_define
class JobRunStarted:
    """
    Attributes:
        run_id (UUID):
        status (JobRunStartedStatus):
        error_code (None | str):
        error (None | str):
    """

    run_id: UUID
    status: JobRunStartedStatus
    error_code: None | str
    error: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        run_id = str(self.run_id)

        status = self.status.value

        error_code: None | str
        error_code = self.error_code

        error: None | str
        error = self.error

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "run_id": run_id,
                "status": status,
                "error_code": error_code,
                "error": error,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        run_id = UUID(d.pop("run_id"))

        status = JobRunStartedStatus(d.pop("status"))

        def _parse_error_code(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        error_code = _parse_error_code(d.pop("error_code"))

        def _parse_error(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        error = _parse_error(d.pop("error"))

        job_run_started = cls(
            run_id=run_id,
            status=status,
            error_code=error_code,
            error=error,
        )

        job_run_started.additional_properties = d
        return job_run_started

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
