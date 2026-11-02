from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AiProcessingJob")


@_attrs_define
class AiProcessingJob:
    """
    Attributes:
        id (UUID):
        job_type (str): Discriminator for worker routing (e.g. categorize_and_tag)
        target_kind (str): Namespace of the target entity (e.g. content.markdown)
        target_id (str): UUID of the target entity
        status (str): Current lifecycle status (queued | claimed | succeeded | dead)
        priority (int): Higher value = claimed first; default 0
        attempts (int): Number of claim attempts so far
        max_attempts (int): Maximum allowed claim attempts before dead-lettering
        created_at (str): Timestamp when the job was enqueued
        updated_at (str): Timestamp of the last status transition
    """

    id: UUID
    job_type: str
    target_kind: str
    target_id: str
    status: str
    priority: int
    attempts: int
    max_attempts: int
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        job_type = self.job_type

        target_kind = self.target_kind

        target_id = self.target_id

        status = self.status

        priority = self.priority

        attempts = self.attempts

        max_attempts = self.max_attempts

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "jobType": job_type,
                "targetKind": target_kind,
                "targetId": target_id,
                "status": status,
                "priority": priority,
                "attempts": attempts,
                "maxAttempts": max_attempts,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        job_type = d.pop("jobType")

        target_kind = d.pop("targetKind")

        target_id = d.pop("targetId")

        status = d.pop("status")

        priority = d.pop("priority")

        attempts = d.pop("attempts")

        max_attempts = d.pop("maxAttempts")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        ai_processing_job = cls(
            id=id,
            job_type=job_type,
            target_kind=target_kind,
            target_id=target_id,
            status=status,
            priority=priority,
            attempts=attempts,
            max_attempts=max_attempts,
            created_at=created_at,
            updated_at=updated_at,
        )

        ai_processing_job.additional_properties = d
        return ai_processing_job

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
