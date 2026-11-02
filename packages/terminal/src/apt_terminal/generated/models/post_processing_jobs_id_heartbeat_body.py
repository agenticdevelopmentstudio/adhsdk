from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProcessingJobsIdHeartbeatBody")


@_attrs_define
class PostProcessingJobsIdHeartbeatBody:
    """
    Attributes:
        lease_token (str): Opaque lease token returned by /claim
        lease_ms (int | Unset): New lease duration in ms (default 30 000)
    """

    lease_token: str
    lease_ms: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        lease_token = self.lease_token

        lease_ms = self.lease_ms

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "leaseToken": lease_token,
            }
        )
        if lease_ms is not UNSET:
            field_dict["leaseMs"] = lease_ms

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        lease_token = d.pop("leaseToken")

        lease_ms = d.pop("leaseMs", UNSET)

        post_processing_jobs_id_heartbeat_body = cls(
            lease_token=lease_token,
            lease_ms=lease_ms,
        )

        post_processing_jobs_id_heartbeat_body.additional_properties = d
        return post_processing_jobs_id_heartbeat_body

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
