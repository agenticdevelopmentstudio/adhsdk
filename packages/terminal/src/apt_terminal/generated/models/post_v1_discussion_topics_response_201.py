from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.discussion_topic_author_kind import DiscussionTopicAuthorKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DiscussionTopicsResponse201")


@_attrs_define
class PostV1DiscussionTopicsResponse201:
    """
    Attributes:
        id (str):
        community_id (str): The community instance this topic belongs to.
        title (str):
        is_pinned (bool):
        is_locked (bool):
        is_public (bool):
        reply_count (int):
        last_activity_at (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        author_kind (DiscussionTopicAuthorKind | Unset): Kind of principal that wrote the topic (omitted on the public
            surface); null when nobody did (a storage token).
        author_id (None | str | Unset): Id of that principal.
        category_id (None | str | Unset):
        answered_post_id (None | str | Unset):
        excerpt (None | str | Unset): LIST routes only: the opening post’s leading prose, flattened from markdown
            server-side (≤240 chars; null when its body doc was soft-deleted). Absent on single-topic reads and
            create/update responses.
        author_name (None | str | Unset): Authed COMMUNITY list route only: the author’s display name. Never on the
            public surface or the flat /discussion/topics list.
        author_slug (None | str | Unset): Authed COMMUNITY list route only: the author’s public handle. Never on the
            public surface or the flat /discussion/topics list.
        author_avatar_url (None | str | Unset): Authed COMMUNITY list route only: the author’s avatar URL. Never on the
            public surface or the flat /discussion/topics list.
        object_ (Literal['discussion.topic'] | Unset):
    """

    id: str
    community_id: str
    title: str
    is_pinned: bool
    is_locked: bool
    is_public: bool
    reply_count: int
    last_activity_at: str
    created: int
    updated: int
    author_kind: DiscussionTopicAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    category_id: None | str | Unset = UNSET
    answered_post_id: None | str | Unset = UNSET
    excerpt: None | str | Unset = UNSET
    author_name: None | str | Unset = UNSET
    author_slug: None | str | Unset = UNSET
    author_avatar_url: None | str | Unset = UNSET
    object_: Literal["discussion.topic"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        community_id = self.community_id

        title = self.title

        is_pinned = self.is_pinned

        is_locked = self.is_locked

        is_public = self.is_public

        reply_count = self.reply_count

        last_activity_at = self.last_activity_at

        created = self.created

        updated = self.updated

        author_kind: str | Unset = UNSET
        if not isinstance(self.author_kind, Unset):
            author_kind = self.author_kind.value

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

        category_id: None | str | Unset
        if isinstance(self.category_id, Unset):
            category_id = UNSET
        else:
            category_id = self.category_id

        answered_post_id: None | str | Unset
        if isinstance(self.answered_post_id, Unset):
            answered_post_id = UNSET
        else:
            answered_post_id = self.answered_post_id

        excerpt: None | str | Unset
        if isinstance(self.excerpt, Unset):
            excerpt = UNSET
        else:
            excerpt = self.excerpt

        author_name: None | str | Unset
        if isinstance(self.author_name, Unset):
            author_name = UNSET
        else:
            author_name = self.author_name

        author_slug: None | str | Unset
        if isinstance(self.author_slug, Unset):
            author_slug = UNSET
        else:
            author_slug = self.author_slug

        author_avatar_url: None | str | Unset
        if isinstance(self.author_avatar_url, Unset):
            author_avatar_url = UNSET
        else:
            author_avatar_url = self.author_avatar_url

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "community_id": community_id,
                "title": title,
                "is_pinned": is_pinned,
                "is_locked": is_locked,
                "is_public": is_public,
                "reply_count": reply_count,
                "last_activity_at": last_activity_at,
                "created": created,
                "updated": updated,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if category_id is not UNSET:
            field_dict["category_id"] = category_id
        if answered_post_id is not UNSET:
            field_dict["answered_post_id"] = answered_post_id
        if excerpt is not UNSET:
            field_dict["excerpt"] = excerpt
        if author_name is not UNSET:
            field_dict["author_name"] = author_name
        if author_slug is not UNSET:
            field_dict["author_slug"] = author_slug
        if author_avatar_url is not UNSET:
            field_dict["author_avatar_url"] = author_avatar_url
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        community_id = d.pop("community_id")

        title = d.pop("title")

        is_pinned = d.pop("is_pinned")

        is_locked = d.pop("is_locked")

        is_public = d.pop("is_public")

        reply_count = d.pop("reply_count")

        last_activity_at = d.pop("last_activity_at")

        created = d.pop("created")

        updated = d.pop("updated")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: DiscussionTopicAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = DiscussionTopicAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_category_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        category_id = _parse_category_id(d.pop("category_id", UNSET))

        def _parse_answered_post_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        answered_post_id = _parse_answered_post_id(d.pop("answered_post_id", UNSET))

        def _parse_excerpt(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        excerpt = _parse_excerpt(d.pop("excerpt", UNSET))

        def _parse_author_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_name = _parse_author_name(d.pop("author_name", UNSET))

        def _parse_author_slug(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_slug = _parse_author_slug(d.pop("author_slug", UNSET))

        def _parse_author_avatar_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_avatar_url = _parse_author_avatar_url(d.pop("author_avatar_url", UNSET))

        object_ = cast(Literal["discussion.topic"] | Unset, d.pop("object", UNSET))
        if object_ != "discussion.topic" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'discussion.topic', got '{object_}'")

        post_v1_discussion_topics_response_201 = cls(
            id=id,
            community_id=community_id,
            title=title,
            is_pinned=is_pinned,
            is_locked=is_locked,
            is_public=is_public,
            reply_count=reply_count,
            last_activity_at=last_activity_at,
            created=created,
            updated=updated,
            author_kind=author_kind,
            author_id=author_id,
            category_id=category_id,
            answered_post_id=answered_post_id,
            excerpt=excerpt,
            author_name=author_name,
            author_slug=author_slug,
            author_avatar_url=author_avatar_url,
            object_=object_,
        )

        post_v1_discussion_topics_response_201.additional_properties = d
        return post_v1_discussion_topics_response_201

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
