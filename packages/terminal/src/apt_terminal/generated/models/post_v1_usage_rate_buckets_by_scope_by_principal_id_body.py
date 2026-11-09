from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageRateBucketsByScopeByPrincipalIdBody")


@_attrs_define
class PostV1UsageRateBucketsByScopeByPrincipalIdBody:
    """
    Attributes:
        scope (str | Unset):
        principal_id (str | Unset):
        tokens_avail (int | Unset):
        refilled_at (str | Unset):
    """

    scope: str | Unset = UNSET
    principal_id: str | Unset = UNSET
    tokens_avail: int | Unset = UNSET
    refilled_at: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        tokens_avail = self.tokens_avail

        refilled_at = self.refilled_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if scope is not UNSET:
            field_dict["scope"] = scope
        if principal_id is not UNSET:
            field_dict["principal_id"] = principal_id
        if tokens_avail is not UNSET:
            field_dict["tokens_avail"] = tokens_avail
        if refilled_at is not UNSET:
            field_dict["refilled_at"] = refilled_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope", UNSET)

        principal_id = d.pop("principal_id", UNSET)

        tokens_avail = d.pop("tokens_avail", UNSET)

        refilled_at = d.pop("refilled_at", UNSET)

        post_v1_usage_rate_buckets_by_scope_by_principal_id_body = cls(
            scope=scope,
            principal_id=principal_id,
            tokens_avail=tokens_avail,
            refilled_at=refilled_at,
        )

        return post_v1_usage_rate_buckets_by_scope_by_principal_id_body
