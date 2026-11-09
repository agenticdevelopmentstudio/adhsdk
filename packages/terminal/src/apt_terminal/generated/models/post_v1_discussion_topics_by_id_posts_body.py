from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DiscussionTopicsByIdPostsBody")


@_attrs_define
class PostV1DiscussionTopicsByIdPostsBody:
    """
    Attributes:
        body (str): Reply markdown; stored as a content.markdown body document.
        parent_post_id (str | Unset): Id of the post this reply nests under (a flat reply when omitted).
    """

    body: str
    parent_post_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        body = self.body

        parent_post_id = self.parent_post_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "body": body,
            }
        )
        if parent_post_id is not UNSET:
            field_dict["parent_post_id"] = parent_post_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        body = d.pop("body")

        parent_post_id = d.pop("parent_post_id", UNSET)

        post_v1_discussion_topics_by_id_posts_body = cls(
            body=body,
            parent_post_id=parent_post_id,
        )

        post_v1_discussion_topics_by_id_posts_body.additional_properties = d
        return post_v1_discussion_topics_by_id_posts_body

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
