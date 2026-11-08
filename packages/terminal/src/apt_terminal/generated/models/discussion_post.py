from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.discussion_post_author_kind import DiscussionPostAuthorKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="DiscussionPost")


@_attrs_define
class DiscussionPost:
    """
    Attributes:
        id (str):
        topic_id (str):
        parent_post_id (None | str):
        post_number (int):
        body_document_id (None | str): The content.markdown doc backing this post’s body.
        created_at (str):
        updated_at (str):
        author_kind (DiscussionPostAuthorKind | Unset): Kind of principal that wrote the post (omitted on the public
            surface); null when nobody did (a storage token).
        author_id (None | str | Unset): Id of that principal.
        ecosystem_id (str | Unset): Owning ecosystem (present on create only).
        community_id (str | Unset): The community instance (inherited from the topic; present on create only).
        content (None | str | Unset): Resolved markdown body (present on the list routes; null if the body doc was
            deleted).
        is_deleted (bool | Unset):
        deleted_at (None | str | Unset):
    """

    id: str
    topic_id: str
    parent_post_id: None | str
    post_number: int
    body_document_id: None | str
    created_at: str
    updated_at: str
    author_kind: DiscussionPostAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    community_id: str | Unset = UNSET
    content: None | str | Unset = UNSET
    is_deleted: bool | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        topic_id = self.topic_id

        parent_post_id: None | str
        parent_post_id = self.parent_post_id

        post_number = self.post_number

        body_document_id: None | str
        body_document_id = self.body_document_id

        created_at = self.created_at

        updated_at = self.updated_at

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

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "topicId": topic_id,
                "parentPostId": parent_post_id,
                "postNumber": post_number,
                "bodyDocumentId": body_document_id,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if author_kind is not UNSET:
            field_dict["authorKind"] = author_kind
        if author_id is not UNSET:
            field_dict["authorId"] = author_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if community_id is not UNSET:
            field_dict["communityId"] = community_id
        if content is not UNSET:
            field_dict["content"] = content
        if is_deleted is not UNSET:
            field_dict["isDeleted"] = is_deleted
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        topic_id = d.pop("topicId")

        def _parse_parent_post_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_post_id = _parse_parent_post_id(d.pop("parentPostId"))

        post_number = d.pop("postNumber")

        def _parse_body_document_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        body_document_id = _parse_body_document_id(d.pop("bodyDocumentId"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        _author_kind = d.pop("authorKind", UNSET)
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

        author_id = _parse_author_id(d.pop("authorId", UNSET))

        ecosystem_id = d.pop("ecosystemId", UNSET)

        community_id = d.pop("communityId", UNSET)

        def _parse_content(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        content = _parse_content(d.pop("content", UNSET))

        is_deleted = d.pop("isDeleted", UNSET)

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        discussion_post = cls(
            id=id,
            topic_id=topic_id,
            parent_post_id=parent_post_id,
            post_number=post_number,
            body_document_id=body_document_id,
            created_at=created_at,
            updated_at=updated_at,
            author_kind=author_kind,
            author_id=author_id,
            ecosystem_id=ecosystem_id,
            community_id=community_id,
            content=content,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
        )

        discussion_post.additional_properties = d
        return discussion_post

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
