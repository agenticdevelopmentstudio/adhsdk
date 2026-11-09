from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1BillingSubscriptionsByIdResponse200")


@_attrs_define
class GetV1BillingSubscriptionsByIdResponse200:
    """
    Attributes:
        id (str):
        user_id (str):
        ecosystem_id (str):
        tier_id (str):
        status (str):
        source (str):
        started_at (str):
        expires_at (None | str):
        assigned_by (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['billing.subscription'] | Unset):
    """

    id: str
    user_id: str
    ecosystem_id: str
    tier_id: str
    status: str
    source: str
    started_at: str
    expires_at: None | str
    assigned_by: None | str
    created: int
    updated: int
    object_: Literal["billing.subscription"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        user_id = self.user_id

        ecosystem_id = self.ecosystem_id

        tier_id = self.tier_id

        status = self.status

        source = self.source

        started_at = self.started_at

        expires_at: None | str
        expires_at = self.expires_at

        assigned_by: None | str
        assigned_by = self.assigned_by

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "user_id": user_id,
                "ecosystem_id": ecosystem_id,
                "tier_id": tier_id,
                "status": status,
                "source": source,
                "started_at": started_at,
                "expires_at": expires_at,
                "assigned_by": assigned_by,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        user_id = d.pop("user_id")

        ecosystem_id = d.pop("ecosystem_id")

        tier_id = d.pop("tier_id")

        status = d.pop("status")

        source = d.pop("source")

        started_at = d.pop("started_at")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expires_at"))

        def _parse_assigned_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        assigned_by = _parse_assigned_by(d.pop("assigned_by"))

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["billing.subscription"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.subscription" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'billing.subscription', got '{object_}'")

        get_v1_billing_subscriptions_by_id_response_200 = cls(
            id=id,
            user_id=user_id,
            ecosystem_id=ecosystem_id,
            tier_id=tier_id,
            status=status,
            source=source,
            started_at=started_at,
            expires_at=expires_at,
            assigned_by=assigned_by,
            created=created,
            updated=updated,
            object_=object_,
        )

        return get_v1_billing_subscriptions_by_id_response_200
