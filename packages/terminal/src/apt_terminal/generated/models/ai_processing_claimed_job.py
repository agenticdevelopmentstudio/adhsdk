from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.ai_processing_claimed_job_payload import AiProcessingClaimedJobPayload


T = TypeVar("T", bound="AiProcessingClaimedJob")


@_attrs_define
class AiProcessingClaimedJob:
    """
    Attributes:
        id (UUID):
        job_type (str): Discriminator for worker routing (e.g. categorize_and_tag)
        target_kind (str): Namespace of the target entity (e.g. content.markdown)
        target_id (str): UUID of the target entity
        payload (AiProcessingClaimedJobPayload): Arbitrary job-specific input
        claimed_at (str): Drizzle-read timestamp of when the job was claimed
        lease_expires_at (str): Drizzle-read timestamp when the lease expires
        lease_token (str): Opaque lease token required for heartbeat / complete / fail
    """

    id: UUID
    job_type: str
    target_kind: str
    target_id: str
    payload: AiProcessingClaimedJobPayload
    claimed_at: str
    lease_expires_at: str
    lease_token: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        job_type = self.job_type

        target_kind = self.target_kind

        target_id = self.target_id

        payload = self.payload.to_dict()

        claimed_at = self.claimed_at

        lease_expires_at = self.lease_expires_at

        lease_token = self.lease_token

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "jobType": job_type,
                "targetKind": target_kind,
                "targetId": target_id,
                "payload": payload,
                "claimedAt": claimed_at,
                "leaseExpiresAt": lease_expires_at,
                "leaseToken": lease_token,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_claimed_job_payload import (
            AiProcessingClaimedJobPayload,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        job_type = d.pop("jobType")

        target_kind = d.pop("targetKind")

        target_id = d.pop("targetId")

        payload = AiProcessingClaimedJobPayload.from_dict(d.pop("payload"))

        claimed_at = d.pop("claimedAt")

        lease_expires_at = d.pop("leaseExpiresAt")

        lease_token = d.pop("leaseToken")

        ai_processing_claimed_job = cls(
            id=id,
            job_type=job_type,
            target_kind=target_kind,
            target_id=target_id,
            payload=payload,
            claimed_at=claimed_at,
            lease_expires_at=lease_expires_at,
            lease_token=lease_token,
        )

        ai_processing_claimed_job.additional_properties = d
        return ai_processing_claimed_job

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
