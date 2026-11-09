from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_enforcement_source import UsageEnforcementSource
from ..models.usage_enforcement_unknown_price_policy import UsageEnforcementUnknownPricePolicy
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_enforcement_flag_type_0 import UsageEnforcementFlagType0


T = TypeVar("T", bound="GetV1UsageEnforcementResponse200")


@_attrs_define
class GetV1UsageEnforcementResponse200:
    """
    Attributes:
        enabled (bool): Effective switch: false ⇒ every tier's quota_enforced is inert (observe only)
        source (UsageEnforcementSource): Which input decided `enabled` — the env override, or the feature-flag row
        env_override (bool | None): USAGE_ENFORCEMENT_ENABLED; null (the normal case) means the flag row decides
        flag (None | UsageEnforcementFlagType0): The system.feature_flags 'usage_enforcement' row; null ⇒ never created
        unknown_price_policy (UsageEnforcementUnknownPricePolicy): What an unpriced model is charged
            (USAGE_UNKNOWN_PRICE_POLICY)
        unknown_price_input_micros_per_m_token (int): Ceiling-policy input rate in µUSD per million tokens
        unknown_price_output_micros_per_m_token (int): Ceiling-policy output rate in µUSD per million tokens
        turn_token_reserve (int): Tokens a signed-in chat turn claims up front (USAGE_TURN_TOKEN_RESERVE)
        event_retention_days (int): Age past which a usage_events row is swept (counters are kept forever)
        visitor_global_daily_token_budget (int | None): Anonymous LLM tokens per day per OWNING ECOSYSTEM
            (VISITOR_GLOBAL_DAILY_TOKEN_BUDGET); refuses regardless of `enabled`. null ⇒ lifted (`off`)
        visitor_global_daily_cost_micros (int | None): The same daily budget in µUSD of provider spend
            (VISITOR_GLOBAL_DAILY_COST_MICROS); refuses regardless of `enabled`. null ⇒ lifted (`off`)
        visitor_turn_token_reserve (int): Tokens an anonymous turn claims up front (VISITOR_TURN_TOKEN_RESERVE); against
            the cost budget the same claim is priced at the output rate
        object_ (Literal['usage.enforcement'] | Unset):
    """

    enabled: bool
    source: UsageEnforcementSource
    env_override: bool | None
    flag: None | UsageEnforcementFlagType0
    unknown_price_policy: UsageEnforcementUnknownPricePolicy
    unknown_price_input_micros_per_m_token: int
    unknown_price_output_micros_per_m_token: int
    turn_token_reserve: int
    event_retention_days: int
    visitor_global_daily_token_budget: int | None
    visitor_global_daily_cost_micros: int | None
    visitor_turn_token_reserve: int
    object_: Literal["usage.enforcement"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.usage_enforcement_flag_type_0 import (
            UsageEnforcementFlagType0,
        )

        enabled = self.enabled

        source = self.source.value

        env_override: bool | None
        env_override = self.env_override

        flag: dict[str, Any] | None
        if isinstance(self.flag, UsageEnforcementFlagType0):
            flag = self.flag.to_dict()
        else:
            flag = self.flag

        unknown_price_policy = self.unknown_price_policy.value

        unknown_price_input_micros_per_m_token = self.unknown_price_input_micros_per_m_token

        unknown_price_output_micros_per_m_token = self.unknown_price_output_micros_per_m_token

        turn_token_reserve = self.turn_token_reserve

        event_retention_days = self.event_retention_days

        visitor_global_daily_token_budget: int | None
        visitor_global_daily_token_budget = self.visitor_global_daily_token_budget

        visitor_global_daily_cost_micros: int | None
        visitor_global_daily_cost_micros = self.visitor_global_daily_cost_micros

        visitor_turn_token_reserve = self.visitor_turn_token_reserve

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "enabled": enabled,
                "source": source,
                "env_override": env_override,
                "flag": flag,
                "unknown_price_policy": unknown_price_policy,
                "unknown_price_input_micros_per_m_token": unknown_price_input_micros_per_m_token,
                "unknown_price_output_micros_per_m_token": unknown_price_output_micros_per_m_token,
                "turn_token_reserve": turn_token_reserve,
                "event_retention_days": event_retention_days,
                "visitor_global_daily_token_budget": visitor_global_daily_token_budget,
                "visitor_global_daily_cost_micros": visitor_global_daily_cost_micros,
                "visitor_turn_token_reserve": visitor_turn_token_reserve,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_enforcement_flag_type_0 import (
            UsageEnforcementFlagType0,
        )

        d = dict(src_dict)
        enabled = d.pop("enabled")

        source = UsageEnforcementSource(d.pop("source"))

        def _parse_env_override(data: object) -> bool | None:
            if data is None:
                return data
            return cast(bool | None, data)

        env_override = _parse_env_override(d.pop("env_override"))

        def _parse_flag(data: object) -> None | UsageEnforcementFlagType0:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                flag_type_0 = UsageEnforcementFlagType0.from_dict(data)

                return flag_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UsageEnforcementFlagType0, data)

        flag = _parse_flag(d.pop("flag"))

        unknown_price_policy = UsageEnforcementUnknownPricePolicy(d.pop("unknown_price_policy"))

        unknown_price_input_micros_per_m_token = d.pop("unknown_price_input_micros_per_m_token")

        unknown_price_output_micros_per_m_token = d.pop("unknown_price_output_micros_per_m_token")

        turn_token_reserve = d.pop("turn_token_reserve")

        event_retention_days = d.pop("event_retention_days")

        def _parse_visitor_global_daily_token_budget(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        visitor_global_daily_token_budget = _parse_visitor_global_daily_token_budget(
            d.pop("visitor_global_daily_token_budget")
        )

        def _parse_visitor_global_daily_cost_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        visitor_global_daily_cost_micros = _parse_visitor_global_daily_cost_micros(
            d.pop("visitor_global_daily_cost_micros")
        )

        visitor_turn_token_reserve = d.pop("visitor_turn_token_reserve")

        object_ = cast(Literal["usage.enforcement"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.enforcement" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.enforcement', got '{object_}'")

        get_v1_usage_enforcement_response_200 = cls(
            enabled=enabled,
            source=source,
            env_override=env_override,
            flag=flag,
            unknown_price_policy=unknown_price_policy,
            unknown_price_input_micros_per_m_token=unknown_price_input_micros_per_m_token,
            unknown_price_output_micros_per_m_token=unknown_price_output_micros_per_m_token,
            turn_token_reserve=turn_token_reserve,
            event_retention_days=event_retention_days,
            visitor_global_daily_token_budget=visitor_global_daily_token_budget,
            visitor_global_daily_cost_micros=visitor_global_daily_cost_micros,
            visitor_turn_token_reserve=visitor_turn_token_reserve,
            object_=object_,
        )

        get_v1_usage_enforcement_response_200.additional_properties = d
        return get_v1_usage_enforcement_response_200

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
