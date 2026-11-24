from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_run_status_status import JobRunStatusStatus

T = TypeVar("T", bound="JobRunStatus")


@_attrs_define
class JobRunStatus:
    """
    Attributes:
        run_id (UUID):
        job_id (UUID):
        job_name (str):
        template_key (None | str): Null for a job with inline steps.
        owner_id (str): The customer who owns the job.
        status (JobRunStatusStatus):
        error_code (None | str):
        error (None | str): The first 200 characters of the run's error.
        started_at (datetime.datetime | None):
        finished_at (datetime.datetime | None):
        created (int): Unix timestamp, in seconds.
    """

    run_id: UUID
    job_id: UUID
    job_name: str
    template_key: None | str
    owner_id: str
    status: JobRunStatusStatus
    error_code: None | str
    error: None | str
    started_at: datetime.datetime | None
    finished_at: datetime.datetime | None
    created: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        run_id = str(self.run_id)

        job_id = str(self.job_id)

        job_name = self.job_name

        template_key: None | str
        template_key = self.template_key

        owner_id = self.owner_id

        status = self.status.value

        error_code: None | str
        error_code = self.error_code

        error: None | str
        error = self.error

        started_at: None | str
        if isinstance(self.started_at, datetime.datetime):
            started_at = self.started_at.isoformat()
        else:
            started_at = self.started_at

        finished_at: None | str
        if isinstance(self.finished_at, datetime.datetime):
            finished_at = self.finished_at.isoformat()
        else:
            finished_at = self.finished_at

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "run_id": run_id,
                "job_id": job_id,
                "job_name": job_name,
                "template_key": template_key,
                "owner_id": owner_id,
                "status": status,
                "error_code": error_code,
                "error": error,
                "started_at": started_at,
                "finished_at": finished_at,
                "created": created,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        run_id = UUID(d.pop("run_id"))

        job_id = UUID(d.pop("job_id"))

        job_name = d.pop("job_name")

        def _parse_template_key(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        template_key = _parse_template_key(d.pop("template_key"))

        owner_id = d.pop("owner_id")

        status = JobRunStatusStatus(d.pop("status"))

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

        def _parse_started_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                started_at_type_0 = datetime.datetime.fromisoformat(data)

                return started_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        started_at = _parse_started_at(d.pop("started_at"))

        def _parse_finished_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                finished_at_type_0 = datetime.datetime.fromisoformat(data)

                return finished_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        finished_at = _parse_finished_at(d.pop("finished_at"))

        created = d.pop("created")

        job_run_status = cls(
            run_id=run_id,
            job_id=job_id,
            job_name=job_name,
            template_key=template_key,
            owner_id=owner_id,
            status=status,
            error_code=error_code,
            error=error,
            started_at=started_at,
            finished_at=finished_at,
            created=created,
        )

        job_run_status.additional_properties = d
        return job_run_status

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
