from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.discussion_post_author_kind import DiscussionPostAuthorKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DiscussionTopicsByIdPostsResponse201")


@_attrs_define
class PostV1DiscussionTopicsByIdPostsResponse201:
    """
    Attributes:
        id (str):
        topic_id (str):
        parent_post_id (None | str):
        post_number (int):
        body_document_id (None | str): The content.markdown doc backing this post’s body.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        author_kind (DiscussionPostAuthorKind | Unset): Kind of principal that wrote the post (omitted on the public
            surface); null when nobody did (a storage token).
        author_id (None | str | Unset): Id of that principal.
        ecosystem_id (str | Unset): Owning ecosystem (present on create only).
        community_id (str | Unset): The community instance (inherited from the topic; present on create only).
        content (None | str | Unset): Resolved markdown body (present on the list routes; null if the body doc was
            deleted).
        is_deleted (bool | Unset):
        deleted_at (None | str | Unset):
        object_ (Literal['post'] | Unset):
    """

    id: str
    topic_id: str
    parent_post_id: None | str
    post_number: int
    body_document_id: None | str
    created: int
    updated: int
    author_kind: DiscussionPostAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    community_id: str | Unset = UNSET
    content: None | str | Unset = UNSET
    is_deleted: bool | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    object_: Literal["post"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        topic_id = self.topic_id

        parent_post_id: None | str
        parent_post_id = self.parent_post_id

        post_number = self.post_number

        body_document_id: None | str
        body_document_id = self.body_document_id

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

        ecosystem_id = self.ecosystem_id

        community_id = self.community_id

        content: None | str | Unset
        if isinstance(self.content, Unset):
            content = UNSET
        else:
            content = self.content

        is_deleted = self.is_deleted

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "topic_id": topic_id,
                "parent_post_id": parent_post_id,
                "post_number": post_number,
                "body_document_id": body_document_id,
                "created": created,
                "updated": updated,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if community_id is not UNSET:
            field_dict["community_id"] = community_id
        if content is not UNSET:
            field_dict["content"] = content
        if is_deleted is not UNSET:
            field_dict["is_deleted"] = is_deleted
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        topic_id = d.pop("topic_id")

        def _parse_parent_post_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_post_id = _parse_parent_post_id(d.pop("parent_post_id"))

        post_number = d.pop("post_number")

        def _parse_body_document_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        body_document_id = _parse_body_document_id(d.pop("body_document_id"))

        created = d.pop("created")

        updated = d.pop("updated")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: DiscussionPostAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = DiscussionPostAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        community_id = d.pop("community_id", UNSET)

        def _parse_content(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        content = _parse_content(d.pop("content", UNSET))

        is_deleted = d.pop("is_deleted", UNSET)

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["post"] | Unset, d.pop("object", UNSET))
        if object_ != "post" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'post', got '{object_}'")

        post_v1_discussion_topics_by_id_posts_response_201 = cls(
            id=id,
            topic_id=topic_id,
            parent_post_id=parent_post_id,
            post_number=post_number,
            body_document_id=body_document_id,
            created=created,
            updated=updated,
            author_kind=author_kind,
            author_id=author_id,
            ecosystem_id=ecosystem_id,
            community_id=community_id,
            content=content,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            object_=object_,
        )

        post_v1_discussion_topics_by_id_posts_response_201.additional_properties = d
        return post_v1_discussion_topics_by_id_posts_response_201

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
