from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="SupportGrantRequest")


@_attrs_define
class SupportGrantRequest:
    """
    Attributes:
        target_id (UUID): A live customer of the product.
        reason (str): 10 to 500 characters (422 otherwise).
        hours (int | Unset): How long the grant runs once approved: 1 to 168 (422 otherwise); 24 if absent.
    """

    target_id: UUID
    reason: str
    hours: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        target_id = str(self.target_id)

        reason = self.reason

        hours = self.hours

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "target_id": target_id,
                "reason": reason,
            }
        )
        if hours is not UNSET:
            field_dict["hours"] = hours

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_id = UUID(d.pop("target_id"))

        reason = d.pop("reason")

        hours = d.pop("hours", UNSET)

        support_grant_request = cls(
            target_id=target_id,
            reason=reason,
            hours=hours,
        )

        return support_grant_request
