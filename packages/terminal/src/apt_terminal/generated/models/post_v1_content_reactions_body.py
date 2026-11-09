from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1ContentReactionsBody")


@_attrs_define
class PostV1ContentReactionsBody:
    """
    Attributes:
        target_kind (str):
        target_id (str):
        emoji (str):
    """

    target_kind: str
    target_id: str
    emoji: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target_kind = self.target_kind

        target_id = self.target_id

        emoji = self.emoji

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "target_kind": target_kind,
                "target_id": target_id,
                "emoji": emoji,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        emoji = d.pop("emoji")

        post_v1_content_reactions_body = cls(
            target_kind=target_kind,
            target_id=target_id,
            emoji=emoji,
        )

        post_v1_content_reactions_body.additional_properties = d
        return post_v1_content_reactions_body

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
