from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProcessingJobsIdFailResponse200")


@_attrs_define
class PostProcessingJobsIdFailResponse200:
    """
    Attributes:
        will_retry (bool): True when the job was re-queued
        run_at (None | str | Unset): Scheduled re-run timestamp (null when dead)
    """

    will_retry: bool
    run_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        will_retry = self.will_retry

        run_at: None | str | Unset
        if isinstance(self.run_at, Unset):
            run_at = UNSET
        else:
            run_at = self.run_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "willRetry": will_retry,
            }
        )
        if run_at is not UNSET:
            field_dict["runAt"] = run_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        will_retry = d.pop("willRetry")

        def _parse_run_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        run_at = _parse_run_at(d.pop("runAt", UNSET))

        post_processing_jobs_id_fail_response_200 = cls(
            will_retry=will_retry,
            run_at=run_at,
        )

        post_processing_jobs_id_fail_response_200.additional_properties = d
        return post_processing_jobs_id_fail_response_200

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
