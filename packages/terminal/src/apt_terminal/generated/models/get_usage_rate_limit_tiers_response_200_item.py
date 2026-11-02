from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetUsageRateLimitTiersResponse200Item")


@_attrs_define
class GetUsageRateLimitTiersResponse200Item:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        rate_capacity (int):
        rate_refill_tokens (int):
        rate_refill_seconds (int):
        quota_requests (int | None):
        quota_bytes (int | None):
        quota_tokens (int | None):
        quota_cost_micros (int | None):
        quota_period_days (int):
        quota_enforced (bool):
        is_default (bool):
        is_active (bool):
        created_at (str):
        updated_at (str):
    """

    id: str
    slug: str
    name: str
    rate_capacity: int
    rate_refill_tokens: int
    rate_refill_seconds: int
    quota_requests: int | None
    quota_bytes: int | None
    quota_tokens: int | None
    quota_cost_micros: int | None
    quota_period_days: int
    quota_enforced: bool
    is_default: bool
    is_active: bool
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        rate_capacity = self.rate_capacity

        rate_refill_tokens = self.rate_refill_tokens

        rate_refill_seconds = self.rate_refill_seconds

        quota_requests: int | None
        quota_requests = self.quota_requests

        quota_bytes: int | None
        quota_bytes = self.quota_bytes

        quota_tokens: int | None
        quota_tokens = self.quota_tokens

        quota_cost_micros: int | None
        quota_cost_micros = self.quota_cost_micros

        quota_period_days = self.quota_period_days

        quota_enforced = self.quota_enforced

        is_default = self.is_default

        is_active = self.is_active

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "rateCapacity": rate_capacity,
                "rateRefillTokens": rate_refill_tokens,
                "rateRefillSeconds": rate_refill_seconds,
                "quotaRequests": quota_requests,
                "quotaBytes": quota_bytes,
                "quotaTokens": quota_tokens,
                "quotaCostMicros": quota_cost_micros,
                "quotaPeriodDays": quota_period_days,
                "quotaEnforced": quota_enforced,
                "isDefault": is_default,
                "isActive": is_active,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        rate_capacity = d.pop("rateCapacity")

        rate_refill_tokens = d.pop("rateRefillTokens")

        rate_refill_seconds = d.pop("rateRefillSeconds")

        def _parse_quota_requests(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_requests = _parse_quota_requests(d.pop("quotaRequests"))

        def _parse_quota_bytes(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_bytes = _parse_quota_bytes(d.pop("quotaBytes"))

        def _parse_quota_tokens(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_tokens = _parse_quota_tokens(d.pop("quotaTokens"))

        def _parse_quota_cost_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_cost_micros = _parse_quota_cost_micros(d.pop("quotaCostMicros"))

        quota_period_days = d.pop("quotaPeriodDays")

        quota_enforced = d.pop("quotaEnforced")

        is_default = d.pop("isDefault")

        is_active = d.pop("isActive")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        get_usage_rate_limit_tiers_response_200_item = cls(
            id=id,
            slug=slug,
            name=name,
            rate_capacity=rate_capacity,
            rate_refill_tokens=rate_refill_tokens,
            rate_refill_seconds=rate_refill_seconds,
            quota_requests=quota_requests,
            quota_bytes=quota_bytes,
            quota_tokens=quota_tokens,
            quota_cost_micros=quota_cost_micros,
            quota_period_days=quota_period_days,
            quota_enforced=quota_enforced,
            is_default=is_default,
            is_active=is_active,
            created_at=created_at,
            updated_at=updated_at,
        )

        return get_usage_rate_limit_tiers_response_200_item
