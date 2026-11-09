from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DiscussionTopicsBody")


@_attrs_define
class PostV1DiscussionTopicsBody:
    """
    Attributes:
        title (str):
        body (str): Opening-post markdown; stored as a content.markdown body document.
        community_id (str): Community instance to create under; the caller must be its admin (else 403).
        category_id (str | Unset): Optional category to file the topic under; must belong to the same community (else
            400).
        is_public (bool | Unset): Whether anonymous callers can read the topic via /public/discussion (default true).
    """

    title: str
    body: str
    community_id: str
    category_id: str | Unset = UNSET
    is_public: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        body = self.body

        community_id = self.community_id

        category_id = self.category_id

        is_public = self.is_public

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "title": title,
                "body": body,
                "community_id": community_id,
            }
        )
        if category_id is not UNSET:
            field_dict["category_id"] = category_id
        if is_public is not UNSET:
            field_dict["is_public"] = is_public

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title")

        body = d.pop("body")

        community_id = d.pop("community_id")

        category_id = d.pop("category_id", UNSET)

        is_public = d.pop("is_public", UNSET)

        post_v1_discussion_topics_body = cls(
            title=title,
            body=body,
            community_id=community_id,
            category_id=category_id,
            is_public=is_public,
        )

        post_v1_discussion_topics_body.additional_properties = d
        return post_v1_discussion_topics_body

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
