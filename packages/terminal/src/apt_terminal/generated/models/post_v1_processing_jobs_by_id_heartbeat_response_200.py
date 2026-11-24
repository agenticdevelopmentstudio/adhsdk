from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProcessingJobsByIdHeartbeatResponse200")


@_attrs_define
class PostV1ProcessingJobsByIdHeartbeatResponse200:
    """
    Attributes:
        lease_expires_at (str): New lease expiry timestamp
        object_ (Literal['processing.job'] | Unset):
    """

    lease_expires_at: str
    object_: Literal["processing.job"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        lease_expires_at = self.lease_expires_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "lease_expires_at": lease_expires_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        lease_expires_at = d.pop("lease_expires_at")

        object_ = cast(Literal["processing.job"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.job" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.job', got '{object_}'")

        post_v1_processing_jobs_by_id_heartbeat_response_200 = cls(
            lease_expires_at=lease_expires_at,
            object_=object_,
        )

        post_v1_processing_jobs_by_id_heartbeat_response_200.additional_properties = d
        return post_v1_processing_jobs_by_id_heartbeat_response_200

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
