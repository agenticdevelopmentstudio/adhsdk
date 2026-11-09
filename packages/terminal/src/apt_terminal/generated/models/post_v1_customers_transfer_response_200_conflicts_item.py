from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CustomersTransferResponse200ConflictsItem")


@_attrs_define
class PostV1CustomersTransferResponse200ConflictsItem:
    """
    Attributes:
        user_id (str | Unset):
        constraint (str | Unset):
        detail (str | Unset):
    """

    user_id: str | Unset = UNSET
    constraint: str | Unset = UNSET
    detail: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        constraint = self.constraint

        detail = self.detail

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if user_id is not UNSET:
            field_dict["user_id"] = user_id
        if constraint is not UNSET:
            field_dict["constraint"] = constraint
        if detail is not UNSET:
            field_dict["detail"] = detail

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("user_id", UNSET)

        constraint = d.pop("constraint", UNSET)

        detail = d.pop("detail", UNSET)

        post_v1_customers_transfer_response_200_conflicts_item = cls(
            user_id=user_id,
            constraint=constraint,
            detail=detail,
        )

        post_v1_customers_transfer_response_200_conflicts_item.additional_properties = d
        return post_v1_customers_transfer_response_200_conflicts_item

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
