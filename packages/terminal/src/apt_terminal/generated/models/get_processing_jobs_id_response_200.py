from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_processing_jobs_id_response_200_status import GetProcessingJobsIdResponse200Status
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetProcessingJobsIdResponse200")


@_attrs_define
class GetProcessingJobsIdResponse200:
    """
    Attributes:
        id (str):
        status (GetProcessingJobsIdResponse200Status):
        result (Any | Unset):
    """

    id: str
    status: GetProcessingJobsIdResponse200Status
    result: Any | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        status = self.status.value

        result = self.result

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "status": status,
            }
        )
        if result is not UNSET:
            field_dict["result"] = result

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        status = GetProcessingJobsIdResponse200Status(d.pop("status"))

        result = d.pop("result", UNSET)

        get_processing_jobs_id_response_200 = cls(
            id=id,
            status=status,
            result=result,
        )

        get_processing_jobs_id_response_200.additional_properties = d
        return get_processing_jobs_id_response_200

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
