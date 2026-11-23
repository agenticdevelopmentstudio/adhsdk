from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

from ..models.system_support_grant_request_target_kind import SystemSupportGrantRequestTargetKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="SystemSupportGrantRequest")


@_attrs_define
class SystemSupportGrantRequest:
    """
    Attributes:
        target_kind (SystemSupportGrantRequestTargetKind):
        target_id (UUID):
        reason (str): 10 to 500 characters (422 otherwise).
        ecosystem_id (UUID | Unset): The customer's product; required for a customer, ignored for a hub account.
        hours (int | Unset): How long the grant runs once approved: 1 to 168 (422 otherwise); 24 if absent.
    """

    target_kind: SystemSupportGrantRequestTargetKind
    target_id: UUID
    reason: str
    ecosystem_id: UUID | Unset = UNSET
    hours: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        target_kind = self.target_kind.value

        target_id = str(self.target_id)

        reason = self.reason

        ecosystem_id: str | Unset = UNSET
        if not isinstance(self.ecosystem_id, Unset):
            ecosystem_id = str(self.ecosystem_id)

        hours = self.hours

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "target_kind": target_kind,
                "target_id": target_id,
                "reason": reason,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if hours is not UNSET:
            field_dict["hours"] = hours

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_kind = SystemSupportGrantRequestTargetKind(d.pop("target_kind"))

        target_id = UUID(d.pop("target_id"))

        reason = d.pop("reason")

        _ecosystem_id = d.pop("ecosystem_id", UNSET)
        ecosystem_id: UUID | Unset
        if isinstance(_ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = UUID(_ecosystem_id)

        hours = d.pop("hours", UNSET)

        system_support_grant_request = cls(
            target_kind=target_kind,
            target_id=target_id,
            reason=reason,
            ecosystem_id=ecosystem_id,
            hours=hours,
        )

        return system_support_grant_request
