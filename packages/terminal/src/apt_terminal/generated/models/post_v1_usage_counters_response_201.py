from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageCountersResponse201")


@_attrs_define
class PostV1UsageCountersResponse201:
    """
    Attributes:
        scope (str):
        principal_id (str):
        period_start (str):
        requests (int):
        bytes_ (int):
        tokens (int):
        cost_micros (int):
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['usage.counter'] | Unset):
    """

    scope: str
    principal_id: str
    period_start: str
    requests: int
    bytes_: int
    tokens: int
    cost_micros: int
    updated: int
    object_: Literal["usage.counter"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        period_start = self.period_start

        requests = self.requests

        bytes_ = self.bytes_

        tokens = self.tokens

        cost_micros = self.cost_micros

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principal_id": principal_id,
                "period_start": period_start,
                "requests": requests,
                "bytes": bytes_,
                "tokens": tokens,
                "cost_micros": cost_micros,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope")

        principal_id = d.pop("principal_id")

        period_start = d.pop("period_start")

        requests = d.pop("requests")

        bytes_ = d.pop("bytes")

        tokens = d.pop("tokens")

        cost_micros = d.pop("cost_micros")

        updated = d.pop("updated")

        object_ = cast(Literal["usage.counter"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.counter" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.counter', got '{object_}'")

        post_v1_usage_counters_response_201 = cls(
            scope=scope,
            principal_id=principal_id,
            period_start=period_start,
            requests=requests,
            bytes_=bytes_,
            tokens=tokens,
            cost_micros=cost_micros,
            updated=updated,
            object_=object_,
        )

        return post_v1_usage_counters_response_201
