from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.sync_push_result import SyncPushResult


T = TypeVar("T", bound="PostV1SyncPushResponse200")


@_attrs_define
class PostV1SyncPushResponse200:
    """
    Attributes:
        results (list[SyncPushResult]):
        watermark (str):
        object_ (Literal['sync.push'] | Unset):
    """

    results: list[SyncPushResult]
    watermark: str
    object_: Literal["sync.push"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        results = []
        for results_item_data in self.results:
            results_item = results_item_data.to_dict()
            results.append(results_item)

        watermark = self.watermark

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "results": results,
                "watermark": watermark,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_push_result import SyncPushResult

        d = dict(src_dict)
        results = []
        _results = d.pop("results")
        for results_item_data in _results:
            results_item = SyncPushResult.from_dict(results_item_data)

            results.append(results_item)

        watermark = d.pop("watermark")

        object_ = cast(Literal["sync.push"] | Unset, d.pop("object", UNSET))
        if object_ != "sync.push" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'sync.push', got '{object_}'")

        post_v1_sync_push_response_200 = cls(
            results=results,
            watermark=watermark,
            object_=object_,
        )

        post_v1_sync_push_response_200.additional_properties = d
        return post_v1_sync_push_response_200

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
