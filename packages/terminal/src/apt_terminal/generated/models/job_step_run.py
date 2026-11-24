from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_step_run_usage import JobStepRunUsage


T = TypeVar("T", bound="JobStepRun")


@_attrs_define
class JobStepRun:
    """
    Attributes:
        id (UUID):
        position (int):
        step_id (None | str):
        name (None | str): The step's name in the run's frozen steps (its pinned version's).
        kind (None | str):
        status (str):
        attempts (int):
        output (Any):
        log (list[str]): The latest lines the executor wrote.
        usage (JobStepRunUsage):
        error_code (None | str):
        error (None | str):
        started_at (datetime.datetime | None):
        finished_at (datetime.datetime | None):
    """

    id: UUID
    position: int
    step_id: None | str
    name: None | str
    kind: None | str
    status: str
    attempts: int
    output: Any
    log: list[str]
    usage: JobStepRunUsage
    error_code: None | str
    error: None | str
    started_at: datetime.datetime | None
    finished_at: datetime.datetime | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        position = self.position

        step_id: None | str
        step_id = self.step_id

        name: None | str
        name = self.name

        kind: None | str
        kind = self.kind

        status = self.status

        attempts = self.attempts

        output = self.output

        log = self.log

        usage = self.usage.to_dict()

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

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "position": position,
                "step_id": step_id,
                "name": name,
                "kind": kind,
                "status": status,
                "attempts": attempts,
                "output": output,
                "log": log,
                "usage": usage,
                "error_code": error_code,
                "error": error,
                "started_at": started_at,
                "finished_at": finished_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_step_run_usage import JobStepRunUsage

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        position = d.pop("position")

        def _parse_step_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        step_id = _parse_step_id(d.pop("step_id"))

        def _parse_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        name = _parse_name(d.pop("name"))

        def _parse_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        kind = _parse_kind(d.pop("kind"))

        status = d.pop("status")

        attempts = d.pop("attempts")

        output = d.pop("output")

        log = cast(list[str], d.pop("log"))

        usage = JobStepRunUsage.from_dict(d.pop("usage"))

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

        job_step_run = cls(
            id=id,
            position=position,
            step_id=step_id,
            name=name,
            kind=kind,
            status=status,
            attempts=attempts,
            output=output,
            log=log,
            usage=usage,
            error_code=error_code,
            error=error,
            started_at=started_at,
            finished_at=finished_at,
        )

        job_step_run.additional_properties = d
        return job_step_run

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
