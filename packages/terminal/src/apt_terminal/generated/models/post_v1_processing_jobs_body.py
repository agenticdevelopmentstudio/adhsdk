from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProcessingJobsBody")


@_attrs_define
class PostV1ProcessingJobsBody:
    """
    Attributes:
        job_type (str): Discriminator for worker routing (e.g. categorize_and_tag)
        target_kind (str): Namespace of the target entity (e.g. content.markdown)
        target_id (str): UUID of the target entity
        payload (Any): Arbitrary job-specific input stored as jsonb
        priority (int | Unset): Higher value = claimed first; defaults to 0
        config_set_id (None | str | Unset): Run under this config set. Requires admin (403 otherwise); an unknown id is
            400.
    """

    job_type: str
    target_kind: str
    target_id: str
    payload: Any
    priority: int | Unset = UNSET
    config_set_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        job_type = self.job_type

        target_kind = self.target_kind

        target_id = self.target_id

        payload = self.payload

        priority = self.priority

        config_set_id: None | str | Unset
        if isinstance(self.config_set_id, Unset):
            config_set_id = UNSET
        else:
            config_set_id = self.config_set_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "job_type": job_type,
                "target_kind": target_kind,
                "target_id": target_id,
                "payload": payload,
            }
        )
        if priority is not UNSET:
            field_dict["priority"] = priority
        if config_set_id is not UNSET:
            field_dict["config_set_id"] = config_set_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        job_type = d.pop("job_type")

        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        payload = d.pop("payload")

        priority = d.pop("priority", UNSET)

        def _parse_config_set_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        config_set_id = _parse_config_set_id(d.pop("config_set_id", UNSET))

        post_v1_processing_jobs_body = cls(
            job_type=job_type,
            target_kind=target_kind,
            target_id=target_id,
            payload=payload,
            priority=priority,
            config_set_id=config_set_id,
        )

        post_v1_processing_jobs_body.additional_properties = d
        return post_v1_processing_jobs_body

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
