from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostUsageRateBucketsResponse201")


@_attrs_define
class PostUsageRateBucketsResponse201:
    """
    Attributes:
        scope (str):
        principal_id (str):
        tokens_avail (int):
        refilled_at (str):
    """

    scope: str
    principal_id: str
    tokens_avail: int
    refilled_at: str

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        tokens_avail = self.tokens_avail

        refilled_at = self.refilled_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principalId": principal_id,
                "tokensAvail": tokens_avail,
                "refilledAt": refilled_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope")

        principal_id = d.pop("principalId")

        tokens_avail = d.pop("tokensAvail")

        refilled_at = d.pop("refilledAt")

        post_usage_rate_buckets_response_201 = cls(
            scope=scope,
            principal_id=principal_id,
            tokens_avail=tokens_avail,
            refilled_at=refilled_at,
        )

        return post_usage_rate_buckets_response_201
