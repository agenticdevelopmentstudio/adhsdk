from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1UsageRateLimitTiersResponse200DataItem")


@_attrs_define
class GetV1UsageRateLimitTiersResponse200DataItem:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['usage.rate_limit_tier'] | Unset):
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
    created: int
    updated: int
    object_: Literal["usage.rate_limit_tier"] | Unset = UNSET

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

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "rate_capacity": rate_capacity,
                "rate_refill_tokens": rate_refill_tokens,
                "rate_refill_seconds": rate_refill_seconds,
                "quota_requests": quota_requests,
                "quota_bytes": quota_bytes,
                "quota_tokens": quota_tokens,
                "quota_cost_micros": quota_cost_micros,
                "quota_period_days": quota_period_days,
                "quota_enforced": quota_enforced,
                "is_default": is_default,
                "is_active": is_active,
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

        slug = d.pop("slug")

        name = d.pop("name")

        rate_capacity = d.pop("rate_capacity")

        rate_refill_tokens = d.pop("rate_refill_tokens")

        rate_refill_seconds = d.pop("rate_refill_seconds")

        def _parse_quota_requests(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_requests = _parse_quota_requests(d.pop("quota_requests"))

        def _parse_quota_bytes(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_bytes = _parse_quota_bytes(d.pop("quota_bytes"))

        def _parse_quota_tokens(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_tokens = _parse_quota_tokens(d.pop("quota_tokens"))

        def _parse_quota_cost_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        quota_cost_micros = _parse_quota_cost_micros(d.pop("quota_cost_micros"))

        quota_period_days = d.pop("quota_period_days")

        quota_enforced = d.pop("quota_enforced")

        is_default = d.pop("is_default")

        is_active = d.pop("is_active")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["usage.rate_limit_tier"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.rate_limit_tier" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.rate_limit_tier', got '{object_}'")

        get_v1_usage_rate_limit_tiers_response_200_data_item = cls(
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
            created=created,
            updated=updated,
            object_=object_,
        )

        return get_v1_usage_rate_limit_tiers_response_200_data_item
