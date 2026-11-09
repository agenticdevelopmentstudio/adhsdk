from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageCountersBody")


@_attrs_define
class PostV1UsageCountersBody:
    """
    Attributes:
        scope (str):
        principal_id (str):
        period_start (str):
        requests (int):
        bytes_ (int):
        tokens (int | Unset):
        cost_micros (int | Unset):
    """

    scope: str
    principal_id: str
    period_start: str
    requests: int
    bytes_: int
    tokens: int | Unset = UNSET
    cost_micros: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        period_start = self.period_start

        requests = self.requests

        bytes_ = self.bytes_

        tokens = self.tokens

        cost_micros = self.cost_micros

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principal_id": principal_id,
                "period_start": period_start,
                "requests": requests,
                "bytes": bytes_,
            }
        )
        if tokens is not UNSET:
            field_dict["tokens"] = tokens
        if cost_micros is not UNSET:
            field_dict["cost_micros"] = cost_micros

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope")

        principal_id = d.pop("principal_id")

        period_start = d.pop("period_start")

        requests = d.pop("requests")

        bytes_ = d.pop("bytes")

        tokens = d.pop("tokens", UNSET)

        cost_micros = d.pop("cost_micros", UNSET)

        post_v1_usage_counters_body = cls(
            scope=scope,
            principal_id=principal_id,
            period_start=period_start,
            requests=requests,
            bytes_=bytes_,
            tokens=tokens,
            cost_micros=cost_micros,
        )

        return post_v1_usage_counters_body
