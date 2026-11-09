from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProcessingRunsBody")


@_attrs_define
class PostV1ProcessingRunsBody:
    """
    Attributes:
        target_kind (str): Saved entity kind, e.g. 'content.markdown'
        target_id (str): Row id of the saved entity
        job_type (str | Unset): Optional; defaults to the registered job for the targetKind
        config_set_id (None | str | Unset): Run under this config set. Requires admin (403 otherwise); an unknown id is
            400.
    """

    target_kind: str
    target_id: str
    job_type: str | Unset = UNSET
    config_set_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target_kind = self.target_kind

        target_id = self.target_id

        job_type = self.job_type

        config_set_id: None | str | Unset
        if isinstance(self.config_set_id, Unset):
            config_set_id = UNSET
        else:
            config_set_id = self.config_set_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "target_kind": target_kind,
                "target_id": target_id,
            }
        )
        if job_type is not UNSET:
            field_dict["job_type"] = job_type
        if config_set_id is not UNSET:
            field_dict["config_set_id"] = config_set_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        job_type = d.pop("job_type", UNSET)

        def _parse_config_set_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        config_set_id = _parse_config_set_id(d.pop("config_set_id", UNSET))

        post_v1_processing_runs_body = cls(
            target_kind=target_kind,
            target_id=target_id,
            job_type=job_type,
            config_set_id=config_set_id,
        )

        post_v1_processing_runs_body.additional_properties = d
        return post_v1_processing_runs_body

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
