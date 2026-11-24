from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ai_processing_worker_usage import AiProcessingWorkerUsage


T = TypeVar("T", bound="PostV1ProcessingJobsByIdFailBody")


@_attrs_define
class PostV1ProcessingJobsByIdFailBody:
    """
    Attributes:
        lease_token (str): Opaque lease token returned by /claim
        error (str): Human-readable error stored as last_error
        retry (bool | Unset): Re-queue if attempts remain (default true)
        usage (list[AiProcessingWorkerUsage] | Unset): LLM usage per provider attempt, token counts normalized:
            inputTokens is NON-cached input; outputTokens includes reasoning; reasoningTokens is its subset.
    """

    lease_token: str
    error: str
    retry: bool | Unset = UNSET
    usage: list[AiProcessingWorkerUsage] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        lease_token = self.lease_token

        error = self.error

        retry = self.retry

        usage: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.usage, Unset):
            usage = []
            for usage_item_data in self.usage:
                usage_item = usage_item_data.to_dict()
                usage.append(usage_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "lease_token": lease_token,
                "error": error,
            }
        )
        if retry is not UNSET:
            field_dict["retry"] = retry
        if usage is not UNSET:
            field_dict["usage"] = usage

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_worker_usage import AiProcessingWorkerUsage

        d = dict(src_dict)
        lease_token = d.pop("lease_token")

        error = d.pop("error")

        retry = d.pop("retry", UNSET)

        _usage = d.pop("usage", UNSET)
        usage: list[AiProcessingWorkerUsage] | Unset = UNSET
        if _usage is not UNSET:
            usage = []
            for usage_item_data in _usage:
                usage_item = AiProcessingWorkerUsage.from_dict(usage_item_data)

                usage.append(usage_item)

        post_v1_processing_jobs_by_id_fail_body = cls(
            lease_token=lease_token,
            error=error,
            retry=retry,
            usage=usage,
        )

        post_v1_processing_jobs_by_id_fail_body.additional_properties = d
        return post_v1_processing_jobs_by_id_fail_body

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
