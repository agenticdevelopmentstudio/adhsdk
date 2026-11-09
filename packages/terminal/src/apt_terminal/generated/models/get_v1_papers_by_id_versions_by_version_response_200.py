from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.markdown_document_version_owner_kind import MarkdownDocumentVersionOwnerKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.markdown_document_version_frontmatter_type_0 import (
        MarkdownDocumentVersionFrontmatterType0,
    )


T = TypeVar("T", bound="GetV1PapersByIdVersionsByVersionResponse200")


@_attrs_define
class GetV1PapersByIdVersionsByVersionResponse200:
    """
    Attributes:
        id (str):
        document_id (str):
        writer_customer_id (str): The revision WRITER.
        ecosystem_id (str):
        owner_kind (MarkdownDocumentVersionOwnerKind): Inherited from the head document at write.
        owner_id (str): Inherited from the head document at write.
        version (int):
        title (str): Document title at this revision (full-state snapshot).
        content (str):
        content_hash (str):
        size_bytes (int):
        created (int): Unix timestamp, in seconds.
        is_deleted (bool):
        deleted_at (None | str | Unset):
        frontmatter (MarkdownDocumentVersionFrontmatterType0 | None | Unset):
        author_type (None | str | Unset):
        author_id (None | str | Unset):
        author_name (None | str | Unset):
        object_ (Literal['version'] | Unset):
    """

    id: str
    document_id: str
    writer_customer_id: str
    ecosystem_id: str
    owner_kind: MarkdownDocumentVersionOwnerKind
    owner_id: str
    version: int
    title: str
    content: str
    content_hash: str
    size_bytes: int
    created: int
    is_deleted: bool
    deleted_at: None | str | Unset = UNSET
    frontmatter: MarkdownDocumentVersionFrontmatterType0 | None | Unset = UNSET
    author_type: None | str | Unset = UNSET
    author_id: None | str | Unset = UNSET
    author_name: None | str | Unset = UNSET
    object_: Literal["version"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.markdown_document_version_frontmatter_type_0 import (
            MarkdownDocumentVersionFrontmatterType0,
        )

        id = self.id

        document_id = self.document_id

        writer_customer_id = self.writer_customer_id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        version = self.version

        title = self.title

        content = self.content

        content_hash = self.content_hash

        size_bytes = self.size_bytes

        created = self.created

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "document_id": document_id,
                "writer_customer_id": writer_customer_id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "version": version,
                "title": title,
                "content": content,
                "content_hash": content_hash,
                "size_bytes": size_bytes,
                "created": created,
                "is_deleted": is_deleted,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if frontmatter is not UNSET:
            field_dict["frontmatter"] = frontmatter
        if author_type is not UNSET:
            field_dict["author_type"] = author_type
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if author_name is not UNSET:
            field_dict["author_name"] = author_name
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.markdown_document_version_frontmatter_type_0 import (
            MarkdownDocumentVersionFrontmatterType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        document_id = d.pop("document_id")

        writer_customer_id = d.pop("writer_customer_id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = MarkdownDocumentVersionOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        version = d.pop("version")

        title = d.pop("title")

        content = d.pop("content")

        content_hash = d.pop("content_hash")

        size_bytes = d.pop("size_bytes")

        created = d.pop("created")

        is_deleted = d.pop("is_deleted")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

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

        author_type = _parse_author_type(d.pop("author_type", UNSET))

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_author_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_name = _parse_author_name(d.pop("author_name", UNSET))

        object_ = cast(Literal["version"] | Unset, d.pop("object", UNSET))
        if object_ != "version" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'version', got '{object_}'")

        get_v1_papers_by_id_versions_by_version_response_200 = cls(
            id=id,
            document_id=document_id,
            writer_customer_id=writer_customer_id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            version=version,
            title=title,
            content=content,
            content_hash=content_hash,
            size_bytes=size_bytes,
            created=created,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            frontmatter=frontmatter,
            author_type=author_type,
            author_id=author_id,
            author_name=author_name,
            object_=object_,
        )

        get_v1_papers_by_id_versions_by_version_response_200.additional_properties = d
        return get_v1_papers_by_id_versions_by_version_response_200

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
