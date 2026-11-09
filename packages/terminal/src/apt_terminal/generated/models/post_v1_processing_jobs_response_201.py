from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProcessingJobsResponse201")


@_attrs_define
class PostV1ProcessingJobsResponse201:
    """
    Attributes:
        id (UUID): ID of the enqueued (or existing deduped) job
        deduped (bool): True when an existing job with the same dedupKey was returned
        object_ (Literal['processing.job'] | Unset):
    """

    id: UUID
    deduped: bool
    object_: Literal["processing.job"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        deduped = self.deduped

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "deduped": deduped,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        deduped = d.pop("deduped")

        object_ = cast(Literal["processing.job"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.job" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.job', got '{object_}'")

        post_v1_processing_jobs_response_201 = cls(
            id=id,
            deduped=deduped,
            object_=object_,
        )

        post_v1_processing_jobs_response_201.additional_properties = d
        return post_v1_processing_jobs_response_201

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
