from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="ProductCustomerQuota")


@_attrs_define
class ProductCustomerQuota:
    """
    Attributes:
        bytes_ (int): At most the default quota (403 above it).
    """

    bytes_: int

    def to_dict(self) -> dict[str, Any]:
        bytes_ = self.bytes_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "bytes": bytes_,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        bytes_ = d.pop("bytes")

        product_customer_quota = cls(
            bytes_=bytes_,
        )

        return product_customer_quota
