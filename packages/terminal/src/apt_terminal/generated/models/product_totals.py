from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="ProductTotals")


@_attrs_define
class ProductTotals:
    """
    Attributes:
        customers (int): Live customers.
        new7d (int): Customers made in the last 7 days.
        new30d (int): Customers made in the last 30 days.
        active7d (int): Customers with usage in the last 7 days.
        active30d (int): Customers with usage in the last 30 days.
        storage_bytes (int): Bytes in the customers' ready attachments.
        pending_invitations (int): Invitations sent and not yet used.
        pending_requests (int): Requests for an invitation.
    """

    customers: int
    new7d: int
    new30d: int
    active7d: int
    active30d: int
    storage_bytes: int
    pending_invitations: int
    pending_requests: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        customers = self.customers

        new7d = self.new7d

        new30d = self.new30d

        active7d = self.active7d

        active30d = self.active30d

        storage_bytes = self.storage_bytes

        pending_invitations = self.pending_invitations

        pending_requests = self.pending_requests

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "customers": customers,
                "new7d": new7d,
                "new30d": new30d,
                "active7d": active7d,
                "active30d": active30d,
                "storage_bytes": storage_bytes,
                "pending_invitations": pending_invitations,
                "pending_requests": pending_requests,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        customers = d.pop("customers")

        new7d = d.pop("new7d")

        new30d = d.pop("new30d")

        active7d = d.pop("active7d")

        active30d = d.pop("active30d")

        storage_bytes = d.pop("storage_bytes")

        pending_invitations = d.pop("pending_invitations")

        pending_requests = d.pop("pending_requests")

        product_totals = cls(
            customers=customers,
            new7d=new7d,
            new30d=new30d,
            active7d=active7d,
            active30d=active30d,
            storage_bytes=storage_bytes,
            pending_invitations=pending_invitations,
            pending_requests=pending_requests,
        )

        product_totals.additional_properties = d
        return product_totals

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
