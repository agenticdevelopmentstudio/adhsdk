from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CustomersTransferBody")


@_attrs_define
class PostV1CustomersTransferBody:
    """
    Attributes:
        user_id (str): the customer's uuid
        target (str): destination ecosystem (uuid or rdid)
        dry_run (bool | Unset): report conflicts without writing
    """

    user_id: str
    target: str
    dry_run: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        target = self.target

        dry_run = self.dry_run

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "user_id": user_id,
                "target": target,
            }
        )
        if dry_run is not UNSET:
            field_dict["dry_run"] = dry_run

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("user_id")

        target = d.pop("target")

        dry_run = d.pop("dry_run", UNSET)

        post_v1_customers_transfer_body = cls(
            user_id=user_id,
            target=target,
            dry_run=dry_run,
        )

        post_v1_customers_transfer_body.additional_properties = d
        return post_v1_customers_transfer_body

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
