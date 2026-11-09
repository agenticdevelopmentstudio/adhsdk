from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageStorageByUserIdResponse200")


@_attrs_define
class PostV1UsageStorageByUserIdResponse200:
    """
    Attributes:
        user_id (str):
        ecosystem_id (str): Ecosystem id the override is scoped to
        quota_bytes (int):
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['usage.storage'] | Unset):
    """

    user_id: str
    ecosystem_id: str
    quota_bytes: int
    updated: int
    object_: Literal["usage.storage"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        ecosystem_id = self.ecosystem_id

        quota_bytes = self.quota_bytes

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "user_id": user_id,
                "ecosystem_id": ecosystem_id,
                "quota_bytes": quota_bytes,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("user_id")

        ecosystem_id = d.pop("ecosystem_id")

        quota_bytes = d.pop("quota_bytes")

        updated = d.pop("updated")

        object_ = cast(Literal["usage.storage"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.storage" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.storage', got '{object_}'")

        post_v1_usage_storage_by_user_id_response_200 = cls(
            user_id=user_id,
            ecosystem_id=ecosystem_id,
            quota_bytes=quota_bytes,
            updated=updated,
            object_=object_,
        )

        post_v1_usage_storage_by_user_id_response_200.additional_properties = d
        return post_v1_usage_storage_by_user_id_response_200

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
