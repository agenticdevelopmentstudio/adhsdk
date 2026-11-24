from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AiProcessingDeadJob")


@_attrs_define
class AiProcessingDeadJob:
    """
    Attributes:
        id (UUID):
        ecosystem_id (str):
        job_type (str):
        attempts (int): Attempts recorded, the last one included
        last_error (None | str):
        failed_at (str): When the row went dead
        target_kind (str):
        target_id (str):
        created (int): Unix timestamp, in seconds.
    """

    id: UUID
    ecosystem_id: str
    job_type: str
    attempts: int
    last_error: None | str
    failed_at: str
    target_kind: str
    target_id: str
    created: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id = self.ecosystem_id

        job_type = self.job_type

        attempts = self.attempts

        last_error: None | str
        last_error = self.last_error

        failed_at = self.failed_at

        target_kind = self.target_kind

        target_id = self.target_id

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "job_type": job_type,
                "attempts": attempts,
                "last_error": last_error,
                "failed_at": failed_at,
                "target_kind": target_kind,
                "target_id": target_id,
                "created": created,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = d.pop("ecosystem_id")

        job_type = d.pop("job_type")

        attempts = d.pop("attempts")

        def _parse_last_error(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_error = _parse_last_error(d.pop("last_error"))

        failed_at = d.pop("failed_at")

        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        created = d.pop("created")

        ai_processing_dead_job = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            job_type=job_type,
            attempts=attempts,
            last_error=last_error,
            failed_at=failed_at,
            target_kind=target_kind,
            target_id=target_id,
            created=created,
        )

        ai_processing_dead_job.additional_properties = d
        return ai_processing_dead_job

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
