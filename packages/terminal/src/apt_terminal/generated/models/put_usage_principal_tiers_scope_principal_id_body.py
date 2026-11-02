from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutUsagePrincipalTiersScopePrincipalIdBody")


@_attrs_define
class PutUsagePrincipalTiersScopePrincipalIdBody:
    """
    Attributes:
        scope (str | Unset):
        principal_id (str | Unset):
        tier_id (str | Unset):
    """

    scope: str | Unset = UNSET
    principal_id: str | Unset = UNSET
    tier_id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        tier_id = self.tier_id

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if scope is not UNSET:
            field_dict["scope"] = scope
        if principal_id is not UNSET:
            field_dict["principalId"] = principal_id
        if tier_id is not UNSET:
            field_dict["tierId"] = tier_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope", UNSET)

        principal_id = d.pop("principalId", UNSET)

        tier_id = d.pop("tierId", UNSET)

        put_usage_principal_tiers_scope_principal_id_body = cls(
            scope=scope,
            principal_id=principal_id,
            tier_id=tier_id,
        )

        return put_usage_principal_tiers_scope_principal_id_body
