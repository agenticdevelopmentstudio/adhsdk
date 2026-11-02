from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="MarkdownDocumentVersionSummary")


@_attrs_define
class MarkdownDocumentVersionSummary:
    """
    Attributes:
        id (str):
        version (int):
        title (str):
        content_hash (str):
        size_bytes (int):
        created_at (str):
        author_type (None | str | Unset):
        author_id (None | str | Unset):
        author_name (None | str | Unset):
    """

    id: str
    version: int
    title: str
    content_hash: str
    size_bytes: int
    created_at: str
    author_type: None | str | Unset = UNSET
    author_id: None | str | Unset = UNSET
    author_name: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        version = self.version

        title = self.title

        content_hash = self.content_hash

        size_bytes = self.size_bytes

        created_at = self.created_at

        author_type: None | str | Unset
        if isinstance(self.author_type, Unset):
            author_type = UNSET
        else:
            author_type = self.author_type

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

        author_name: None | str | Unset
        if isinstance(self.author_name, Unset):
            author_name = UNSET
        else:
            author_name = self.author_name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "version": version,
                "title": title,
                "contentHash": content_hash,
                "sizeBytes": size_bytes,
                "createdAt": created_at,
            }
        )
        if author_type is not UNSET:
            field_dict["authorType"] = author_type
        if author_id is not UNSET:
            field_dict["authorId"] = author_id
        if author_name is not UNSET:
            field_dict["authorName"] = author_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        version = d.pop("version")

        title = d.pop("title")

        content_hash = d.pop("contentHash")

        size_bytes = d.pop("sizeBytes")

        created_at = d.pop("createdAt")

        def _parse_author_type(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_type = _parse_author_type(d.pop("authorType", UNSET))

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("authorId", UNSET))

        def _parse_author_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_name = _parse_author_name(d.pop("authorName", UNSET))

        markdown_document_version_summary = cls(
            id=id,
            version=version,
            title=title,
            content_hash=content_hash,
            size_bytes=size_bytes,
            created_at=created_at,
            author_type=author_type,
            author_id=author_id,
            author_name=author_name,
        )

        markdown_document_version_summary.additional_properties = d
        return markdown_document_version_summary

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
