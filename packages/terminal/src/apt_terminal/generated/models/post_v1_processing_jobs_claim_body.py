from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_provider_kind import AiProcessingProviderKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProcessingJobsClaimBody")


@_attrs_define
class PostV1ProcessingJobsClaimBody:
    """
    Attributes:
        job_types (list[str] | Unset): Filter to specific job types; absent = any type
        min_priority (int | Unset): Claim only jobs with priority >= this value (interactive lane = 100)
        batch (int | Unset): Max jobs to claim (default 1)
        lease_ms (int | Unset): Lease duration in ms (default 30 000)
        worker_id (str | Unset): Label for the claimed rows; defaults to api-token name or userId
        providers (list[AiProcessingProviderKind] | Unset): LLM providers this node can run; only jobs resolving to one
            of them are claimed. Absent = ['local'].
    """

    job_types: list[str] | Unset = UNSET
    min_priority: int | Unset = UNSET
    batch: int | Unset = UNSET
    lease_ms: int | Unset = UNSET
    worker_id: str | Unset = UNSET
    providers: list[AiProcessingProviderKind] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        job_types: list[str] | Unset = UNSET
        if not isinstance(self.job_types, Unset):
            job_types = self.job_types

        min_priority = self.min_priority

        batch = self.batch

        lease_ms = self.lease_ms

        worker_id = self.worker_id

        providers: list[str] | Unset = UNSET
        if not isinstance(self.providers, Unset):
            providers = []
            for providers_item_data in self.providers:
                providers_item = providers_item_data.value
                providers.append(providers_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if job_types is not UNSET:
            field_dict["job_types"] = job_types
        if min_priority is not UNSET:
            field_dict["min_priority"] = min_priority
        if batch is not UNSET:
            field_dict["batch"] = batch
        if lease_ms is not UNSET:
            field_dict["lease_ms"] = lease_ms
        if worker_id is not UNSET:
            field_dict["worker_id"] = worker_id
        if providers is not UNSET:
            field_dict["providers"] = providers

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        job_types = cast(list[str], d.pop("job_types", UNSET))

        min_priority = d.pop("min_priority", UNSET)

        batch = d.pop("batch", UNSET)

        lease_ms = d.pop("lease_ms", UNSET)

        worker_id = d.pop("worker_id", UNSET)

        _providers = d.pop("providers", UNSET)
        providers: list[AiProcessingProviderKind] | Unset = UNSET
        if _providers is not UNSET:
            providers = []
            for providers_item_data in _providers:
                providers_item = AiProcessingProviderKind(providers_item_data)

                providers.append(providers_item)

        post_v1_processing_jobs_claim_body = cls(
            job_types=job_types,
            min_priority=min_priority,
            batch=batch,
            lease_ms=lease_ms,
            worker_id=worker_id,
            providers=providers,
        )

        post_v1_processing_jobs_claim_body.additional_properties = d
        return post_v1_processing_jobs_claim_body

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
