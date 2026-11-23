from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

from ..models.support_break_glass_request_target_kind import SupportBreakGlassRequestTargetKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="SupportBreakGlassRequest")


@_attrs_define
class SupportBreakGlassRequest:
    """
    Attributes:
        target_kind (SupportBreakGlassRequestTargetKind):
        target_id (UUID):
        reason (str): 10 to 500 characters (422 otherwise).
        attestation (str): 40 characters or more (422 otherwise).
        attestation_ref (str): The case or incident reference.
        ecosystem_id (UUID | Unset): The customer's product; required for a customer, ignored for a hub account.
        hours (int | Unset): 1 to 4 (422 otherwise); 1 if absent.
    """

    target_kind: SupportBreakGlassRequestTargetKind
    target_id: UUID
    reason: str
    attestation: str
    attestation_ref: str
    ecosystem_id: UUID | Unset = UNSET
    hours: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        target_kind = self.target_kind.value

        target_id = str(self.target_id)

        reason = self.reason

        attestation = self.attestation

        attestation_ref = self.attestation_ref

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
                "attestation": attestation,
                "attestation_ref": attestation_ref,
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
        target_kind = SupportBreakGlassRequestTargetKind(d.pop("target_kind"))

        target_id = UUID(d.pop("target_id"))

        reason = d.pop("reason")

        attestation = d.pop("attestation")

        attestation_ref = d.pop("attestation_ref")

        _ecosystem_id = d.pop("ecosystem_id", UNSET)
        ecosystem_id: UUID | Unset
        if isinstance(_ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = UUID(_ecosystem_id)

        hours = d.pop("hours", UNSET)

        support_break_glass_request = cls(
            target_kind=target_kind,
            target_id=target_id,
            reason=reason,
            attestation=attestation,
            attestation_ref=attestation_ref,
            ecosystem_id=ecosystem_id,
            hours=hours,
        )

        return support_break_glass_request
