from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageRateLimitTiersByIdBody")


@_attrs_define
class PostV1UsageRateLimitTiersByIdBody:
    """
    Attributes:
        slug (str | Unset):
        name (str | Unset):
        rate_capacity (int | Unset):
        rate_refill_tokens (int | Unset):
        rate_refill_seconds (int | Unset):
        quota_requests (int | None | Unset):
        quota_bytes (int | None | Unset):
        quota_tokens (int | None | Unset):
        quota_cost_micros (int | None | Unset):
        quota_period_days (int | Unset):
        quota_enforced (bool | Unset):
        is_default (bool | Unset):
        is_active (bool | Unset):
    """

    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    rate_capacity: int | Unset = UNSET
    rate_refill_tokens: int | Unset = UNSET
    rate_refill_seconds: int | Unset = UNSET
    quota_requests: int | None | Unset = UNSET
    quota_bytes: int | None | Unset = UNSET
    quota_tokens: int | None | Unset = UNSET
    quota_cost_micros: int | None | Unset = UNSET
    quota_period_days: int | Unset = UNSET
    quota_enforced: bool | Unset = UNSET
    is_default: bool | Unset = UNSET
    is_active: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        rate_capacity = self.rate_capacity

        rate_refill_tokens = self.rate_refill_tokens

        rate_refill_seconds = self.rate_refill_seconds

        quota_requests: int | None | Unset
        if isinstance(self.quota_requests, Unset):
            quota_requests = UNSET
        else:
            quota_requests = self.quota_requests

        quota_bytes: int | None | Unset
        if isinstance(self.quota_bytes, Unset):
            quota_bytes = UNSET
        else:
            quota_bytes = self.quota_bytes

        quota_tokens: int | None | Unset
        if isinstance(self.quota_tokens, Unset):
            quota_tokens = UNSET
        else:
            quota_tokens = self.quota_tokens

        quota_cost_micros: int | None | Unset
        if isinstance(self.quota_cost_micros, Unset):
            quota_cost_micros = UNSET
        else:
            quota_cost_micros = self.quota_cost_micros

        quota_period_days = self.quota_period_days

        quota_enforced = self.quota_enforced

        is_default = self.is_default

        is_active = self.is_active

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if rate_capacity is not UNSET:
            field_dict["rate_capacity"] = rate_capacity
        if rate_refill_tokens is not UNSET:
            field_dict["rate_refill_tokens"] = rate_refill_tokens
        if rate_refill_seconds is not UNSET:
            field_dict["rate_refill_seconds"] = rate_refill_seconds
        if quota_requests is not UNSET:
            field_dict["quota_requests"] = quota_requests
        if quota_bytes is not UNSET:
            field_dict["quota_bytes"] = quota_bytes
        if quota_tokens is not UNSET:
            field_dict["quota_tokens"] = quota_tokens
        if quota_cost_micros is not UNSET:
            field_dict["quota_cost_micros"] = quota_cost_micros
        if quota_period_days is not UNSET:
            field_dict["quota_period_days"] = quota_period_days
        if quota_enforced is not UNSET:
            field_dict["quota_enforced"] = quota_enforced
        if is_default is not UNSET:
            field_dict["is_default"] = is_default
        if is_active is not UNSET:
            field_dict["is_active"] = is_active

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        rate_capacity = d.pop("rate_capacity", UNSET)

        rate_refill_tokens = d.pop("rate_refill_tokens", UNSET)

        rate_refill_seconds = d.pop("rate_refill_seconds", UNSET)

        def _parse_quota_requests(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        quota_requests = _parse_quota_requests(d.pop("quota_requests", UNSET))

        def _parse_quota_bytes(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        quota_bytes = _parse_quota_bytes(d.pop("quota_bytes", UNSET))

        def _parse_quota_tokens(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        quota_tokens = _parse_quota_tokens(d.pop("quota_tokens", UNSET))

        def _parse_quota_cost_micros(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        quota_cost_micros = _parse_quota_cost_micros(d.pop("quota_cost_micros", UNSET))

        quota_period_days = d.pop("quota_period_days", UNSET)

        quota_enforced = d.pop("quota_enforced", UNSET)

        is_default = d.pop("is_default", UNSET)

        is_active = d.pop("is_active", UNSET)

        post_v1_usage_rate_limit_tiers_by_id_body = cls(
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
        )

        return post_v1_usage_rate_limit_tiers_by_id_body
