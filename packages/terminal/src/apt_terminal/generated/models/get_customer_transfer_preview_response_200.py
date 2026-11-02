from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_customer_transfer_preview_response_200_conflicts_item import (
        GetCustomerTransferPreviewResponse200ConflictsItem,
    )


T = TypeVar("T", bound="GetCustomerTransferPreviewResponse200")


@_attrs_define
class GetCustomerTransferPreviewResponse200:
    """
    Attributes:
        target (str | Unset):
        conflicts (list[GetCustomerTransferPreviewResponse200ConflictsItem] | Unset):
    """

    target: str | Unset = UNSET
    conflicts: list[GetCustomerTransferPreviewResponse200ConflictsItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target = self.target

        conflicts: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.conflicts, Unset):
            conflicts = []
            for conflicts_item_data in self.conflicts:
                conflicts_item = conflicts_item_data.to_dict()
                conflicts.append(conflicts_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if target is not UNSET:
            field_dict["target"] = target
        if conflicts is not UNSET:
            field_dict["conflicts"] = conflicts

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_customer_transfer_preview_response_200_conflicts_item import (
            GetCustomerTransferPreviewResponse200ConflictsItem,
        )

        d = dict(src_dict)
        target = d.pop("target", UNSET)

        _conflicts = d.pop("conflicts", UNSET)
        conflicts: list[GetCustomerTransferPreviewResponse200ConflictsItem] | Unset = UNSET
        if _conflicts is not UNSET:
            conflicts = []
            for conflicts_item_data in _conflicts:
                conflicts_item = GetCustomerTransferPreviewResponse200ConflictsItem.from_dict(
                    conflicts_item_data
                )

                conflicts.append(conflicts_item)

        get_customer_transfer_preview_response_200 = cls(
            target=target,
            conflicts=conflicts,
        )

        get_customer_transfer_preview_response_200.additional_properties = d
        return get_customer_transfer_preview_response_200

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
