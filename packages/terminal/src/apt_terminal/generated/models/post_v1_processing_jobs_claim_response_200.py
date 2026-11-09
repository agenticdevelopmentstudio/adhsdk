from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ai_processing_claimed_job import AiProcessingClaimedJob


T = TypeVar("T", bound="PostV1ProcessingJobsClaimResponse200")


@_attrs_define
class PostV1ProcessingJobsClaimResponse200:
    """
    Attributes:
        jobs (list[AiProcessingClaimedJob]):
        object_ (Literal['processing.job'] | Unset):
    """

    jobs: list[AiProcessingClaimedJob]
    object_: Literal["processing.job"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        jobs = []
        for jobs_item_data in self.jobs:
            jobs_item = jobs_item_data.to_dict()
            jobs.append(jobs_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "jobs": jobs,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_claimed_job import AiProcessingClaimedJob

        d = dict(src_dict)
        jobs = []
        _jobs = d.pop("jobs")
        for jobs_item_data in _jobs:
            jobs_item = AiProcessingClaimedJob.from_dict(jobs_item_data)

            jobs.append(jobs_item)

        object_ = cast(Literal["processing.job"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.job" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.job', got '{object_}'")

        post_v1_processing_jobs_claim_response_200 = cls(
            jobs=jobs,
            object_=object_,
        )

        post_v1_processing_jobs_claim_response_200.additional_properties = d
        return post_v1_processing_jobs_claim_response_200

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
