from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutUsageUsageCountersScopePrincipalIdPeriodStartResponse200")


@_attrs_define
class PutUsageUsageCountersScopePrincipalIdPeriodStartResponse200:
    """
    Attributes:
        scope (str):
        principal_id (str):
        period_start (str):
        requests (int):
        bytes_ (int):
        tokens (int):
        cost_micros (int):
        updated_at (str):
    """

    scope: str
    principal_id: str
    period_start: str
    requests: int
    bytes_: int
    tokens: int
    cost_micros: int
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        period_start = self.period_start

        requests = self.requests

        bytes_ = self.bytes_

        tokens = self.tokens

        cost_micros = self.cost_micros

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principalId": principal_id,
                "periodStart": period_start,
                "requests": requests,
                "bytes": bytes_,
                "tokens": tokens,
                "costMicros": cost_micros,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope")

        principal_id = d.pop("principalId")

        period_start = d.pop("periodStart")

        requests = d.pop("requests")

        bytes_ = d.pop("bytes")

        tokens = d.pop("tokens")

        cost_micros = d.pop("costMicros")

        updated_at = d.pop("updatedAt")

        put_usage_usage_counters_scope_principal_id_period_start_response_200 = cls(
            scope=scope,
            principal_id=principal_id,
            period_start=period_start,
            requests=requests,
            bytes_=bytes_,
            tokens=tokens,
            cost_micros=cost_micros,
            updated_at=updated_at,
        )

        return put_usage_usage_counters_scope_principal_id_period_start_response_200
