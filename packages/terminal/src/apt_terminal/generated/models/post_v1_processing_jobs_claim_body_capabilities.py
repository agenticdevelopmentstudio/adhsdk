from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1ProcessingJobsClaimBodyCapabilities")


@_attrs_define
class PostV1ProcessingJobsClaimBodyCapabilities:
    """A machine only: what it can run, recorded on its environment with last_seen_at. Ignored for a worker or pool token.

    Attributes:
        job_types (list[str]):
        providers (list[str]): Provider kinds the machine can run, `claude-code` included
        scripts (bool): Whether jobs.step.script is registered
    """

    job_types: list[str]
    providers: list[str]
    scripts: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        job_types = self.job_types

        providers = self.providers

        scripts = self.scripts

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "job_types": job_types,
                "providers": providers,
                "scripts": scripts,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        job_types = cast(list[str], d.pop("job_types"))

        providers = cast(list[str], d.pop("providers"))

        scripts = d.pop("scripts")

        post_v1_processing_jobs_claim_body_capabilities = cls(
            job_types=job_types,
            providers=providers,
            scripts=scripts,
        )

        post_v1_processing_jobs_claim_body_capabilities.additional_properties = d
        return post_v1_processing_jobs_claim_body_capabilities

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
