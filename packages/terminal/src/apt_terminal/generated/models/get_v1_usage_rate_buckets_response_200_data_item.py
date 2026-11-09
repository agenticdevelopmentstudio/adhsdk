from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1UsageRateBucketsResponse200DataItem")


@_attrs_define
class GetV1UsageRateBucketsResponse200DataItem:
    """
    Attributes:
        scope (str):
        principal_id (str):
        tokens_avail (int):
        refilled_at (str):
        object_ (Literal['usage.rate_bucket'] | Unset):
    """

    scope: str
    principal_id: str
    tokens_avail: int
    refilled_at: str
    object_: Literal["usage.rate_bucket"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        tokens_avail = self.tokens_avail

        refilled_at = self.refilled_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principal_id": principal_id,
                "tokens_avail": tokens_avail,
                "refilled_at": refilled_at,
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

        tokens_avail = d.pop("tokens_avail")

        refilled_at = d.pop("refilled_at")

        object_ = cast(Literal["usage.rate_bucket"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.rate_bucket" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.rate_bucket', got '{object_}'")

        get_v1_usage_rate_buckets_response_200_data_item = cls(
            scope=scope,
            principal_id=principal_id,
            tokens_avail=tokens_avail,
            refilled_at=refilled_at,
            object_=object_,
        )

        return get_v1_usage_rate_buckets_response_200_data_item
