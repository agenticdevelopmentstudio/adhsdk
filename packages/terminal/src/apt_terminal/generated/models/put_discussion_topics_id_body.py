from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutDiscussionTopicsIdBody")


@_attrs_define
class PutDiscussionTopicsIdBody:
    """
    Attributes:
        title (str | Unset):
        is_pinned (bool | Unset): Community moderator only.
        is_locked (bool | Unset): Community moderator only.
        answered_post_id (None | str | Unset): Topic author or community moderator; must be a live post in this topic
            (or null to clear).
    """

    title: str | Unset = UNSET
    is_pinned: bool | Unset = UNSET
    is_locked: bool | Unset = UNSET
    answered_post_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        is_pinned = self.is_pinned

        is_locked = self.is_locked

        answered_post_id: None | str | Unset
        if isinstance(self.answered_post_id, Unset):
            answered_post_id = UNSET
        else:
            answered_post_id = self.answered_post_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if title is not UNSET:
            field_dict["title"] = title
        if is_pinned is not UNSET:
            field_dict["isPinned"] = is_pinned
        if is_locked is not UNSET:
            field_dict["isLocked"] = is_locked
        if answered_post_id is not UNSET:
            field_dict["answeredPostId"] = answered_post_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title", UNSET)

        is_pinned = d.pop("isPinned", UNSET)

        is_locked = d.pop("isLocked", UNSET)

        def _parse_answered_post_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        answered_post_id = _parse_answered_post_id(d.pop("answeredPostId", UNSET))

        put_discussion_topics_id_body = cls(
            title=title,
            is_pinned=is_pinned,
            is_locked=is_locked,
            answered_post_id=answered_post_id,
        )

        put_discussion_topics_id_body.additional_properties = d
        return put_discussion_topics_id_body

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
