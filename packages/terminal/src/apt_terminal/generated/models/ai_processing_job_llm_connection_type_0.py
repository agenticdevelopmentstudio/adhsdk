from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="AiProcessingJobLlmConnectionType0")


@_attrs_define
class AiProcessingJobLlmConnectionType0:
    """Non-secret connection shape only; null for local sets and services with no spec

    Attributes:
        auth (Any | Unset): How the node authenticates to the provider (no credential)
        default_query (Any | Unset): Query parameters the provider call always carries
    """

    auth: Any | Unset = UNSET
    default_query: Any | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        auth = self.auth

        default_query = self.default_query

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if auth is not UNSET:
            field_dict["auth"] = auth
        if default_query is not UNSET:
            field_dict["defaultQuery"] = default_query

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        auth = d.pop("auth", UNSET)

        default_query = d.pop("defaultQuery", UNSET)

        ai_processing_job_llm_connection_type_0 = cls(
            auth=auth,
            default_query=default_query,
        )

        ai_processing_job_llm_connection_type_0.additional_properties = d
        return ai_processing_job_llm_connection_type_0

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
