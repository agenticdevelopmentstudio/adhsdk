from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_content_markdown_id_body_author import PutContentMarkdownIdBodyAuthor


T = TypeVar("T", bound="PutContentMarkdownIdBody")


@_attrs_define
class PutContentMarkdownIdBody:
    """At least one of content/category/tags. A content change appends a full-state version (author attaches to it) and re-
    derives the title; a category/tags-only change updates the head in place WITHOUT a new version; a no-op returns the
    doc unchanged.

        Attributes:
            content (str | Unset): New raw markdown; a real change bumps current_version and re-derives the title.
            category (None | str | Unset): Classification label; send null to clear, omit to leave unchanged.
            tags (list[str] | Unset): Replacement tag set (trimmed + de-duplicated); omit to leave unchanged.
            author (PutContentMarkdownIdBodyAuthor | Unset): Author of this revision; omit to attribute to the calling
                customer. customer/user are pinned to the caller; other types are caller-asserted (unverified).
    """

    content: str | Unset = UNSET
    category: None | str | Unset = UNSET
    tags: list[str] | Unset = UNSET
    author: PutContentMarkdownIdBodyAuthor | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        content = self.content

        category: None | str | Unset
        if isinstance(self.category, Unset):
            category = UNSET
        else:
            category = self.category

        tags: list[str] | Unset = UNSET
        if not isinstance(self.tags, Unset):
            tags = self.tags

        author: dict[str, Any] | Unset = UNSET
        if not isinstance(self.author, Unset):
            author = self.author.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if content is not UNSET:
            field_dict["content"] = content
        if category is not UNSET:
            field_dict["category"] = category
        if tags is not UNSET:
            field_dict["tags"] = tags
        if author is not UNSET:
            field_dict["author"] = author

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_content_markdown_id_body_author import (
            PutContentMarkdownIdBodyAuthor,
        )

        d = dict(src_dict)
        content = d.pop("content", UNSET)

        def _parse_category(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        category = _parse_category(d.pop("category", UNSET))

        tags = cast(list[str], d.pop("tags", UNSET))

        _author = d.pop("author", UNSET)
        author: PutContentMarkdownIdBodyAuthor | Unset
        if isinstance(_author, Unset):
            author = UNSET
        else:
            author = PutContentMarkdownIdBodyAuthor.from_dict(_author)

        put_content_markdown_id_body = cls(
            content=content,
            category=category,
            tags=tags,
            author=author,
        )

        put_content_markdown_id_body.additional_properties = d
        return put_content_markdown_id_body

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
