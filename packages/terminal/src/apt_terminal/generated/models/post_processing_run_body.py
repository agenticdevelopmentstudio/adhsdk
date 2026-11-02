from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProcessingRunBody")


@_attrs_define
class PostProcessingRunBody:
    """
    Attributes:
        target_kind (str): Saved entity kind, e.g. 'content.markdown'
        target_id (str): Row id of the saved entity
        job_type (str | Unset): Optional; defaults to the registered job for the targetKind
    """

    target_kind: str
    target_id: str
    job_type: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target_kind = self.target_kind

        target_id = self.target_id

        job_type = self.job_type

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "targetKind": target_kind,
                "targetId": target_id,
            }
        )
        if job_type is not UNSET:
            field_dict["jobType"] = job_type

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_kind = d.pop("targetKind")

        target_id = d.pop("targetId")

        job_type = d.pop("jobType", UNSET)

        post_processing_run_body = cls(
            target_kind=target_kind,
            target_id=target_id,
            job_type=job_type,
        )

        post_processing_run_body.additional_properties = d
        return post_processing_run_body

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
