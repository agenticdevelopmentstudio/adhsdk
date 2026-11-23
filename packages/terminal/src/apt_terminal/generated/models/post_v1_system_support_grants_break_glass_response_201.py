from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.support_grant_consent import SupportGrantConsent
from ..models.support_grant_decision import SupportGrantDecision
from ..models.support_grant_revoked_by_kind import SupportGrantRevokedByKind
from ..models.support_grant_scope import SupportGrantScope
from ..models.support_grant_status import SupportGrantStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.support_grant_grantee import SupportGrantGrantee
    from ..models.support_grant_target import SupportGrantTarget


T = TypeVar("T", bound="PostV1SystemSupportGrantsBreakGlassResponse201")


@_attrs_define
class PostV1SystemSupportGrantsBreakGlassResponse201:
    """
    Attributes:
        id (UUID):
        ecosystem_id (UUID):
        target (SupportGrantTarget):
        grantee (SupportGrantGrantee):
        reason (str):
        scope (SupportGrantScope):
        consent (SupportGrantConsent):
        status (SupportGrantStatus):
        requested_hours (int): How long the grant runs once approved.
        requested_at (datetime.datetime):
        decision (SupportGrantDecision):
        decided_at (datetime.datetime | None):
        expires_at (datetime.datetime | None):
        revoked_at (datetime.datetime | None):
        revoked_by_kind (SupportGrantRevokedByKind):
        grantee_id (UUID | Unset): Operators only.
        attestation (None | str | Unset): Operators only.
        attestation_ref (None | str | Unset): Operators only.
        object_ (Literal['system.support_grants.break_glass'] | Unset):
    """

    id: UUID
    ecosystem_id: UUID
    target: SupportGrantTarget
    grantee: SupportGrantGrantee
    reason: str
    scope: SupportGrantScope
    consent: SupportGrantConsent
    status: SupportGrantStatus
    requested_hours: int
    requested_at: datetime.datetime
    decision: SupportGrantDecision
    decided_at: datetime.datetime | None
    expires_at: datetime.datetime | None
    revoked_at: datetime.datetime | None
    revoked_by_kind: SupportGrantRevokedByKind
    grantee_id: UUID | Unset = UNSET
    attestation: None | str | Unset = UNSET
    attestation_ref: None | str | Unset = UNSET
    object_: Literal["system.support_grants.break_glass"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id = str(self.ecosystem_id)

        target = self.target.to_dict()

        grantee = self.grantee.to_dict()

        reason = self.reason

        scope = self.scope.value

        consent = self.consent.value

        status = self.status.value

        requested_hours = self.requested_hours

        requested_at = self.requested_at.isoformat()

        decision = self.decision.value

        decided_at: None | str
        if isinstance(self.decided_at, datetime.datetime):
            decided_at = self.decided_at.isoformat()
        else:
            decided_at = self.decided_at

        expires_at: None | str
        if isinstance(self.expires_at, datetime.datetime):
            expires_at = self.expires_at.isoformat()
        else:
            expires_at = self.expires_at

        revoked_at: None | str
        if isinstance(self.revoked_at, datetime.datetime):
            revoked_at = self.revoked_at.isoformat()
        else:
            revoked_at = self.revoked_at

        revoked_by_kind = self.revoked_by_kind.value

        grantee_id: str | Unset = UNSET
        if not isinstance(self.grantee_id, Unset):
            grantee_id = str(self.grantee_id)

        attestation: None | str | Unset
        if isinstance(self.attestation, Unset):
            attestation = UNSET
        else:
            attestation = self.attestation

        attestation_ref: None | str | Unset
        if isinstance(self.attestation_ref, Unset):
            attestation_ref = UNSET
        else:
            attestation_ref = self.attestation_ref

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "target": target,
                "grantee": grantee,
                "reason": reason,
                "scope": scope,
                "consent": consent,
                "status": status,
                "requested_hours": requested_hours,
                "requested_at": requested_at,
                "decision": decision,
                "decided_at": decided_at,
                "expires_at": expires_at,
                "revoked_at": revoked_at,
                "revoked_by_kind": revoked_by_kind,
            }
        )
        if grantee_id is not UNSET:
            field_dict["grantee_id"] = grantee_id
        if attestation is not UNSET:
            field_dict["attestation"] = attestation
        if attestation_ref is not UNSET:
            field_dict["attestation_ref"] = attestation_ref
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.support_grant_grantee import SupportGrantGrantee
        from ..models.support_grant_target import SupportGrantTarget

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = UUID(d.pop("ecosystem_id"))

        target = SupportGrantTarget.from_dict(d.pop("target"))

        grantee = SupportGrantGrantee.from_dict(d.pop("grantee"))

        reason = d.pop("reason")

        scope = SupportGrantScope(d.pop("scope"))

        consent = SupportGrantConsent(d.pop("consent"))

        status = SupportGrantStatus(d.pop("status"))

        requested_hours = d.pop("requested_hours")

        requested_at = datetime.datetime.fromisoformat(d.pop("requested_at"))

        decision = SupportGrantDecision(d.pop("decision"))

        def _parse_decided_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                decided_at_type_0 = datetime.datetime.fromisoformat(data)

                return decided_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        decided_at = _parse_decided_at(d.pop("decided_at"))

        def _parse_expires_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                expires_at_type_0 = datetime.datetime.fromisoformat(data)

                return expires_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        expires_at = _parse_expires_at(d.pop("expires_at"))

        def _parse_revoked_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                revoked_at_type_0 = datetime.datetime.fromisoformat(data)

                return revoked_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        revoked_at = _parse_revoked_at(d.pop("revoked_at"))

        revoked_by_kind = SupportGrantRevokedByKind(d.pop("revoked_by_kind"))

        _grantee_id = d.pop("grantee_id", UNSET)
        grantee_id: UUID | Unset
        if isinstance(_grantee_id, Unset):
            grantee_id = UNSET
        else:
            grantee_id = UUID(_grantee_id)

        def _parse_attestation(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        attestation = _parse_attestation(d.pop("attestation", UNSET))

        def _parse_attestation_ref(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        attestation_ref = _parse_attestation_ref(d.pop("attestation_ref", UNSET))

        object_ = cast(Literal["system.support_grants.break_glass"] | Unset, d.pop("object", UNSET))
        if object_ != "system.support_grants.break_glass" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'system.support_grants.break_glass', got '{object_}'"
            )

        post_v1_system_support_grants_break_glass_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            target=target,
            grantee=grantee,
            reason=reason,
            scope=scope,
            consent=consent,
            status=status,
            requested_hours=requested_hours,
            requested_at=requested_at,
            decision=decision,
            decided_at=decided_at,
            expires_at=expires_at,
            revoked_at=revoked_at,
            revoked_by_kind=revoked_by_kind,
            grantee_id=grantee_id,
            attestation=attestation,
            attestation_ref=attestation_ref,
            object_=object_,
        )

        post_v1_system_support_grants_break_glass_response_201.additional_properties = d
        return post_v1_system_support_grants_break_glass_response_201

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
