from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1UsagePrincipalTiersResponse200DataItem")


@_attrs_define
class GetV1UsagePrincipalTiersResponse200DataItem:
    """
    Attributes:
        scope (str):
        principal_id (str):
        tier_id (str):
        object_ (Literal['usage.principal_tier'] | Unset):
    """

    scope: str
    principal_id: str
    tier_id: str
    object_: Literal["usage.principal_tier"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        tier_id = self.tier_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principal_id": principal_id,
                "tier_id": tier_id,
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

        tier_id = d.pop("tier_id")

        object_ = cast(Literal["usage.principal_tier"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.principal_tier" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.principal_tier', got '{object_}'")

        get_v1_usage_principal_tiers_response_200_data_item = cls(
            scope=scope,
            principal_id=principal_id,
            tier_id=tier_id,
            object_=object_,
        )

        return get_v1_usage_principal_tiers_response_200_data_item
