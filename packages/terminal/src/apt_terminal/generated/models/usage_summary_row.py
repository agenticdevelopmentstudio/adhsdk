from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_summary_row_kind import UsageSummaryRowKind
from ..models.usage_summary_row_scope import UsageSummaryRowScope

if TYPE_CHECKING:
    from ..models.usage_limits import UsageLimits


T = TypeVar("T", bound="UsageSummaryRow")


@_attrs_define
class UsageSummaryRow:
    """
    Attributes:
        kind (UsageSummaryRowKind):
        scope (UsageSummaryRowScope):
        principal_id (str):
        label (str): Display name (user, token or persona name)
        period_start (str): ISO date the current accounting window opened
        period_days (int): Window length in days
        tier (str): Slug of the rate-limit tier governing this principal
        limits (UsageLimits):
        requests (int):
        bytes_ (int): HTTP request + response bytes
        tokens (int): LLM input + output tokens
        cost_micros (int): Provider spend in integer micro-dollars (µUSD)
    """

    kind: UsageSummaryRowKind
    scope: UsageSummaryRowScope
    principal_id: str
    label: str
    period_start: str
    period_days: int
    tier: str
    limits: UsageLimits
    requests: int
    bytes_: int
    tokens: int
    cost_micros: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        scope = self.scope.value

        principal_id = self.principal_id

        label = self.label

        period_start = self.period_start

        period_days = self.period_days

        tier = self.tier

        limits = self.limits.to_dict()

        requests = self.requests

        bytes_ = self.bytes_

        tokens = self.tokens

        cost_micros = self.cost_micros

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "scope": scope,
                "principalId": principal_id,
                "label": label,
                "periodStart": period_start,
                "periodDays": period_days,
                "tier": tier,
                "limits": limits,
                "requests": requests,
                "bytes": bytes_,
                "tokens": tokens,
                "costMicros": cost_micros,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_limits import UsageLimits

        d = dict(src_dict)
        kind = UsageSummaryRowKind(d.pop("kind"))

        scope = UsageSummaryRowScope(d.pop("scope"))

        principal_id = d.pop("principalId")

        label = d.pop("label")

        period_start = d.pop("periodStart")

        period_days = d.pop("periodDays")

        tier = d.pop("tier")

        limits = UsageLimits.from_dict(d.pop("limits"))

        requests = d.pop("requests")

        bytes_ = d.pop("bytes")

        tokens = d.pop("tokens")

        cost_micros = d.pop("costMicros")

        usage_summary_row = cls(
            kind=kind,
            scope=scope,
            principal_id=principal_id,
            label=label,
            period_start=period_start,
            period_days=period_days,
            tier=tier,
            limits=limits,
            requests=requests,
            bytes_=bytes_,
            tokens=tokens,
            cost_micros=cost_micros,
        )

        usage_summary_row.additional_properties = d
        return usage_summary_row

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
