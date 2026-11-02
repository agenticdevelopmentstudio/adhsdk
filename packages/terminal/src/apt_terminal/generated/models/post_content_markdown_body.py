from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_content_markdown_body_author import PostContentMarkdownBodyAuthor


T = TypeVar("T", bound="PostContentMarkdownBody")


@_attrs_define
class PostContentMarkdownBody:
    """
    Attributes:
        content (str): Full raw markdown (stored byte-exact). The title is derived from it — see the response `title`.
        category (str | Unset): Optional classification label.
        tags (list[str] | Unset): Optional tag set (trimmed + de-duplicated server-side).
        author (PostContentMarkdownBodyAuthor | Unset): Author of this revision; omit to attribute to the calling
            customer. customer/user are pinned to the caller; other types are caller-asserted (unverified).
        note (bool | Unset): Send `true` to file the new document in the owner's `notes` storage bucket (mints its
            content.notes marker). It stays an ordinary markdown document in every other respect — same versions, same
            category/tags — and `?noted=true` is how you list them back.
        doc (bool | Unset): Send `true` to file the new document in the owner's `docs` storage bucket (mints its
            content.docs marker). Independent of `note` — the markers are separate rows — and `?doc=true` is how you list
            them back.
    """

    content: str
    category: str | Unset = UNSET
    tags: list[str] | Unset = UNSET
    author: PostContentMarkdownBodyAuthor | Unset = UNSET
    note: bool | Unset = UNSET
    doc: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        content = self.content

        category = self.category

        tags: list[str] | Unset = UNSET
        if not isinstance(self.tags, Unset):
            tags = self.tags

        author: dict[str, Any] | Unset = UNSET
        if not isinstance(self.author, Unset):
            author = self.author.to_dict()

        note = self.note

        doc = self.doc

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "content": content,
            }
        )
        if category is not UNSET:
            field_dict["category"] = category
        if tags is not UNSET:
            field_dict["tags"] = tags
        if author is not UNSET:
            field_dict["author"] = author
        if note is not UNSET:
            field_dict["note"] = note
        if doc is not UNSET:
            field_dict["doc"] = doc

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_content_markdown_body_author import (
            PostContentMarkdownBodyAuthor,
        )

        d = dict(src_dict)
        content = d.pop("content")

        category = d.pop("category", UNSET)

        tags = cast(list[str], d.pop("tags", UNSET))

        _author = d.pop("author", UNSET)
        author: PostContentMarkdownBodyAuthor | Unset
        if isinstance(_author, Unset):
            author = UNSET
        else:
            author = PostContentMarkdownBodyAuthor.from_dict(_author)

        note = d.pop("note", UNSET)

        doc = d.pop("doc", UNSET)

        post_content_markdown_body = cls(
            content=content,
            category=category,
            tags=tags,
            author=author,
            note=note,
            doc=doc,
        )

        post_content_markdown_body.additional_properties = d
        return post_content_markdown_body

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
