from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="SetGrantCreate")


@_attrs_define
class SetGrantCreate:
    """
    Attributes:
        customer_id (UUID):
        set_id (UUID):
    """

    customer_id: UUID
    set_id: UUID

    def to_dict(self) -> dict[str, Any]:
        customer_id = str(self.customer_id)

        set_id = str(self.set_id)

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "customer_id": customer_id,
                "set_id": set_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        customer_id = UUID(d.pop("customer_id"))

        set_id = UUID(d.pop("set_id"))

        set_grant_create = cls(
            customer_id=customer_id,
            set_id=set_id,
        )

        return set_grant_create
