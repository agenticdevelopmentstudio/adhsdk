from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.markdown_document_version_owner_kind import MarkdownDocumentVersionOwnerKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.markdown_document_version_frontmatter_type_0 import (
        MarkdownDocumentVersionFrontmatterType0,
    )


T = TypeVar("T", bound="MarkdownDocumentVersion")


@_attrs_define
class MarkdownDocumentVersion:
    """
    Attributes:
        id (str):
        document_id (str):
        customer_id (str): The revision WRITER.
        ecosystem_id (str):
        owner_kind (MarkdownDocumentVersionOwnerKind): Inherited from the head document at write.
        owner_id (str): Inherited from the head document at write.
        version (int):
        title (str): Document title at this revision (full-state snapshot).
        content (str):
        content_hash (str):
        size_bytes (int):
        created_at (str):
        is_deleted (bool):
        deleted_at (None | str | Unset):
        frontmatter (MarkdownDocumentVersionFrontmatterType0 | None | Unset):
        author_type (None | str | Unset):
        author_id (None | str | Unset):
        author_name (None | str | Unset):
    """

    id: str
    document_id: str
    customer_id: str
    ecosystem_id: str
    owner_kind: MarkdownDocumentVersionOwnerKind
    owner_id: str
    version: int
    title: str
    content: str
    content_hash: str
    size_bytes: int
    created_at: str
    is_deleted: bool
    deleted_at: None | str | Unset = UNSET
    frontmatter: MarkdownDocumentVersionFrontmatterType0 | None | Unset = UNSET
    author_type: None | str | Unset = UNSET
    author_id: None | str | Unset = UNSET
    author_name: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.markdown_document_version_frontmatter_type_0 import (
            MarkdownDocumentVersionFrontmatterType0,
        )

        id = self.id

        document_id = self.document_id

        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        version = self.version

        title = self.title

        content = self.content

        content_hash = self.content_hash

        size_bytes = self.size_bytes

        created_at = self.created_at

        is_deleted = self.is_deleted

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        frontmatter: dict[str, Any] | None | Unset
        if isinstance(self.frontmatter, Unset):
            frontmatter = UNSET
        elif isinstance(self.frontmatter, MarkdownDocumentVersionFrontmatterType0):
            frontmatter = self.frontmatter.to_dict()
        else:
            frontmatter = self.frontmatter

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
                "documentId": document_id,
                "customerId": customer_id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "version": version,
                "title": title,
                "content": content,
                "contentHash": content_hash,
                "sizeBytes": size_bytes,
                "createdAt": created_at,
                "isDeleted": is_deleted,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at
        if frontmatter is not UNSET:
            field_dict["frontmatter"] = frontmatter
        if author_type is not UNSET:
            field_dict["authorType"] = author_type
        if author_id is not UNSET:
            field_dict["authorId"] = author_id
        if author_name is not UNSET:
            field_dict["authorName"] = author_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.markdown_document_version_frontmatter_type_0 import (
            MarkdownDocumentVersionFrontmatterType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        document_id = d.pop("documentId")

        customer_id = d.pop("customerId")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = MarkdownDocumentVersionOwnerKind(d.pop("ownerKind"))

        owner_id = d.pop("ownerId")

        version = d.pop("version")

        title = d.pop("title")

        content = d.pop("content")

        content_hash = d.pop("contentHash")

        size_bytes = d.pop("sizeBytes")

        created_at = d.pop("createdAt")

        is_deleted = d.pop("isDeleted")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        def _parse_frontmatter(
            data: object,
        ) -> MarkdownDocumentVersionFrontmatterType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                frontmatter_type_0 = MarkdownDocumentVersionFrontmatterType0.from_dict(data)

                return frontmatter_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(MarkdownDocumentVersionFrontmatterType0 | None | Unset, data)

        frontmatter = _parse_frontmatter(d.pop("frontmatter", UNSET))

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

        markdown_document_version = cls(
            id=id,
            document_id=document_id,
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            version=version,
            title=title,
            content=content,
            content_hash=content_hash,
            size_bytes=size_bytes,
            created_at=created_at,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            frontmatter=frontmatter,
            author_type=author_type,
            author_id=author_id,
            author_name=author_name,
        )

        markdown_document_version.additional_properties = d
        return markdown_document_version

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
