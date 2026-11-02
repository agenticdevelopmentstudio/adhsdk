from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutUsageUsageCountersScopePrincipalIdPeriodStartBody")


@_attrs_define
class PutUsageUsageCountersScopePrincipalIdPeriodStartBody:
    """
    Attributes:
        scope (str | Unset):
        principal_id (str | Unset):
        period_start (str | Unset):
        requests (int | Unset):
        bytes_ (int | Unset):
        tokens (int | Unset):
        cost_micros (int | Unset):
    """

    scope: str | Unset = UNSET
    principal_id: str | Unset = UNSET
    period_start: str | Unset = UNSET
    requests: int | Unset = UNSET
    bytes_: int | Unset = UNSET
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

        field_dict.update({})
        if scope is not UNSET:
            field_dict["scope"] = scope
        if principal_id is not UNSET:
            field_dict["principalId"] = principal_id
        if period_start is not UNSET:
            field_dict["periodStart"] = period_start
        if requests is not UNSET:
            field_dict["requests"] = requests
        if bytes_ is not UNSET:
            field_dict["bytes"] = bytes_
        if tokens is not UNSET:
            field_dict["tokens"] = tokens
        if cost_micros is not UNSET:
            field_dict["costMicros"] = cost_micros

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope", UNSET)

        principal_id = d.pop("principalId", UNSET)

        period_start = d.pop("periodStart", UNSET)

        requests = d.pop("requests", UNSET)

        bytes_ = d.pop("bytes", UNSET)

        tokens = d.pop("tokens", UNSET)

        cost_micros = d.pop("costMicros", UNSET)

        put_usage_usage_counters_scope_principal_id_period_start_body = cls(
            scope=scope,
            principal_id=principal_id,
            period_start=period_start,
            requests=requests,
            bytes_=bytes_,
            tokens=tokens,
            cost_micros=cost_micros,
        )

        return put_usage_usage_counters_scope_principal_id_period_start_body
