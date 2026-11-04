from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostProcessingNodesRegisterResponse200")


@_attrs_define
class PostProcessingNodesRegisterResponse200:
    """
    Attributes:
        id (str):
        log_retention_days (int): How long the node logs live
    """

    id: str
    log_retention_days: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        log_retention_days = self.log_retention_days

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "logRetentionDays": log_retention_days,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        log_retention_days = d.pop("logRetentionDays")

        post_processing_nodes_register_response_200 = cls(
            id=id,
            log_retention_days=log_retention_days,
        )

        post_processing_nodes_register_response_200.additional_properties = d
        return post_processing_nodes_register_response_200

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
