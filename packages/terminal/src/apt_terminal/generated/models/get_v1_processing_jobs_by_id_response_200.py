from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_processing_jobs_by_id_response_200_status import (
    GetV1ProcessingJobsByIdResponse200Status,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ProcessingJobsByIdResponse200")


@_attrs_define
class GetV1ProcessingJobsByIdResponse200:
    """
    Attributes:
        id (str):
        status (GetV1ProcessingJobsByIdResponse200Status):
        object_ (Literal['processing.job'] | Unset):
        result (Any | Unset):
    """

    id: str
    status: GetV1ProcessingJobsByIdResponse200Status
    object_: Literal["processing.job"] | Unset = UNSET
    result: Any | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        status = self.status.value

        object_ = self.object_

        result = self.result

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "status": status,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if result is not UNSET:
            field_dict["result"] = result

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        status = GetV1ProcessingJobsByIdResponse200Status(d.pop("status"))

        object_ = cast(Literal["processing.job"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.job" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.job', got '{object_}'")

        result = d.pop("result", UNSET)

        get_v1_processing_jobs_by_id_response_200 = cls(
            id=id,
            status=status,
            object_=object_,
            result=result,
        )

        get_v1_processing_jobs_by_id_response_200.additional_properties = d
        return get_v1_processing_jobs_by_id_response_200

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
