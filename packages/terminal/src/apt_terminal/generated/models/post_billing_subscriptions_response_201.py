from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostBillingSubscriptionsResponse201")


@_attrs_define
class PostBillingSubscriptionsResponse201:
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
        created_at (str):
        updated_at (str):
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
    created_at: str
    updated_at: str

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

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "userId": user_id,
                "ecosystemId": ecosystem_id,
                "tierId": tier_id,
                "status": status,
                "source": source,
                "startedAt": started_at,
                "expiresAt": expires_at,
                "assignedBy": assigned_by,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        user_id = d.pop("userId")

        ecosystem_id = d.pop("ecosystemId")

        tier_id = d.pop("tierId")

        status = d.pop("status")

        source = d.pop("source")

        started_at = d.pop("startedAt")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expiresAt"))

        def _parse_assigned_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        assigned_by = _parse_assigned_by(d.pop("assignedBy"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        post_billing_subscriptions_response_201 = cls(
            id=id,
            user_id=user_id,
            ecosystem_id=ecosystem_id,
            tier_id=tier_id,
            status=status,
            source=source,
            started_at=started_at,
            expires_at=expires_at,
            assigned_by=assigned_by,
            created_at=created_at,
            updated_at=updated_at,
        )

        return post_billing_subscriptions_response_201
