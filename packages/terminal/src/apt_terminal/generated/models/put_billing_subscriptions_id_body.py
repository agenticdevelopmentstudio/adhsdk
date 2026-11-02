from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutBillingSubscriptionsIdBody")


@_attrs_define
class PutBillingSubscriptionsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        tier_id (str | Unset):
        status (str | Unset):
        source (str | Unset):
        started_at (str | Unset):
        expires_at (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    tier_id: str | Unset = UNSET
    status: str | Unset = UNSET
    source: str | Unset = UNSET
    started_at: str | Unset = UNSET
    expires_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        tier_id = self.tier_id

        status = self.status

        source = self.source

        started_at = self.started_at

        expires_at: None | str | Unset
        if isinstance(self.expires_at, Unset):
            expires_at = UNSET
        else:
            expires_at = self.expires_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if tier_id is not UNSET:
            field_dict["tierId"] = tier_id
        if status is not UNSET:
            field_dict["status"] = status
        if source is not UNSET:
            field_dict["source"] = source
        if started_at is not UNSET:
            field_dict["startedAt"] = started_at
        if expires_at is not UNSET:
            field_dict["expiresAt"] = expires_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        tier_id = d.pop("tierId", UNSET)

        status = d.pop("status", UNSET)

        source = d.pop("source", UNSET)

        started_at = d.pop("startedAt", UNSET)

        def _parse_expires_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        expires_at = _parse_expires_at(d.pop("expiresAt", UNSET))

        put_billing_subscriptions_id_body = cls(
            ecosystem_id=ecosystem_id,
            tier_id=tier_id,
            status=status,
            source=source,
            started_at=started_at,
            expires_at=expires_at,
        )

        return put_billing_subscriptions_id_body
