from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.ai_processing_dead_job import AiProcessingDeadJob


T = TypeVar("T", bound="AiProcessingDeadJobPage")


@_attrs_define
class AiProcessingDeadJobPage:
    """
    Attributes:
        jobs (list[AiProcessingDeadJob]):
        next_before (None | str): Pass as `before` for the next (older) page; null = no more. Opaque.
    """

    jobs: list[AiProcessingDeadJob]
    next_before: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        jobs = []
        for jobs_item_data in self.jobs:
            jobs_item = jobs_item_data.to_dict()
            jobs.append(jobs_item)

        next_before: None | str
        next_before = self.next_before

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "jobs": jobs,
                "next_before": next_before,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_dead_job import AiProcessingDeadJob

        d = dict(src_dict)
        jobs = []
        _jobs = d.pop("jobs")
        for jobs_item_data in _jobs:
            jobs_item = AiProcessingDeadJob.from_dict(jobs_item_data)

            jobs.append(jobs_item)

        def _parse_next_before(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        next_before = _parse_next_before(d.pop("next_before"))

        ai_processing_dead_job_page = cls(
            jobs=jobs,
            next_before=next_before,
        )

        ai_processing_dead_job_page.additional_properties = d
        return ai_processing_dead_job_page

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
