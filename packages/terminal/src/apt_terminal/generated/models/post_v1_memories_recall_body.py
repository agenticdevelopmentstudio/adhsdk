from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_memories_recall_body_scope import PostV1MemoriesRecallBodyScope
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MemoriesRecallBody")


@_attrs_define
class PostV1MemoriesRecallBody:
    """
    Attributes:
        scope (PostV1MemoriesRecallBodyScope | Unset): Selects which kind of object this call works on.
    """

    scope: PostV1MemoriesRecallBodyScope | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        scope: str | Unset = UNSET
        if not isinstance(self.scope, Unset):
            scope = self.scope.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if scope is not UNSET:
            field_dict["scope"] = scope

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _scope = d.pop("scope", UNSET)
        scope: PostV1MemoriesRecallBodyScope | Unset
        if isinstance(_scope, Unset):
            scope = UNSET
        else:
            scope = PostV1MemoriesRecallBodyScope(_scope)

        post_v1_memories_recall_body = cls(
            scope=scope,
        )

        post_v1_memories_recall_body.additional_properties = d
        return post_v1_memories_recall_body

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
