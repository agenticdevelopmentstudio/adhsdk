from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.markdown_document_author_kind import MarkdownDocumentAuthorKind
from ..models.markdown_document_kind import MarkdownDocumentKind
from ..models.markdown_document_owner_kind import MarkdownDocumentOwnerKind
from ..models.markdown_document_stage import MarkdownDocumentStage
from ..models.markdown_document_visibility import MarkdownDocumentVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.markdown_document_frontmatter_type_0 import MarkdownDocumentFrontmatterType0


T = TypeVar("T", bound="GetV1PapersByIdResponse200")


@_attrs_define
class GetV1PapersByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str): Ecosystem (tenant) id.
        owner_kind (MarkdownDocumentOwnerKind): The kind of principal that OWNS the doc (what access scopes by).
        owner_id (str): The owning principal (customer or organization id); server-stamped from the verified ?workspace=
            scope, else the creator.
        title (str): Server-derived, read-only: the frontmatter `title` then `name`, else the first non-empty line of
            the body (frontmatter and code fences ignored, leading markdown syntax stripped), else 'Untitled'. Capped at 500
            characters.
        content (str): Full raw markdown, byte-exact.
        tags (list[str]): Tag set (defaults to []).
        visibility (MarkdownDocumentVisibility): Publication state: 'public' is readable on the public surface,
            'private' is a draft.
        stage (MarkdownDocumentStage): Editorial stage: 'draft' is editable; 'final' is immutable (content edits +
            version writes are rejected).
        kind (MarkdownDocumentKind): Document kind: 'paper' (ordinary) or 'research' (AI-ingested, carries an adh_source
            frontmatter key).
        content_hash (str): SHA-256 hex of content (ETag).
        size_bytes (int):
        current_version (int): The current revision number (incremented on every edit).
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        author_kind (MarkdownDocumentAuthorKind | Unset): Kind of principal that created the doc (public routes key on a
            customer author); null when nobody did (a storage token).
        author_id (None | str | Unset): Id of that principal.
        deleted_at (None | str | Unset):
        frontmatter (MarkdownDocumentFrontmatterType0 | None | Unset):
        category (None | str | Unset): Optional classification label.
        public_route (None | str | Unset): Public route slug (non-null iff visibility='public'); unique per author.
        latest_version_id (None | str | Unset):
        object_ (Literal['paper'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: MarkdownDocumentOwnerKind
    owner_id: str
    title: str
    content: str
    tags: list[str]
    visibility: MarkdownDocumentVisibility
    stage: MarkdownDocumentStage
    kind: MarkdownDocumentKind
    content_hash: str
    size_bytes: int
    current_version: int
    created: int
    updated: int
    is_deleted: bool
    author_kind: MarkdownDocumentAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    frontmatter: MarkdownDocumentFrontmatterType0 | None | Unset = UNSET
    category: None | str | Unset = UNSET
    public_route: None | str | Unset = UNSET
    latest_version_id: None | str | Unset = UNSET
    object_: Literal["paper"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.markdown_document_frontmatter_type_0 import (
            MarkdownDocumentFrontmatterType0,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        title = self.title

        content = self.content

        tags = self.tags

        visibility = self.visibility.value

        stage = self.stage.value

        kind = self.kind.value

        content_hash = self.content_hash

        size_bytes = self.size_bytes

        current_version = self.current_version

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        author_kind: str | Unset = UNSET
        if not isinstance(self.author_kind, Unset):
            author_kind = self.author_kind.value

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        frontmatter: dict[str, Any] | None | Unset
        if isinstance(self.frontmatter, Unset):
            frontmatter = UNSET
        elif isinstance(self.frontmatter, MarkdownDocumentFrontmatterType0):
            frontmatter = self.frontmatter.to_dict()
        else:
            frontmatter = self.frontmatter

        category: None | str | Unset
        if isinstance(self.category, Unset):
            category = UNSET
        else:
            category = self.category

        public_route: None | str | Unset
        if isinstance(self.public_route, Unset):
            public_route = UNSET
        else:
            public_route = self.public_route

        latest_version_id: None | str | Unset
        if isinstance(self.latest_version_id, Unset):
            latest_version_id = UNSET
        else:
            latest_version_id = self.latest_version_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "title": title,
                "content": content,
                "tags": tags,
                "visibility": visibility,
                "stage": stage,
                "kind": kind,
                "content_hash": content_hash,
                "size_bytes": size_bytes,
                "current_version": current_version,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if frontmatter is not UNSET:
            field_dict["frontmatter"] = frontmatter
        if category is not UNSET:
            field_dict["category"] = category
        if public_route is not UNSET:
            field_dict["public_route"] = public_route
        if latest_version_id is not UNSET:
            field_dict["latest_version_id"] = latest_version_id
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.markdown_document_frontmatter_type_0 import (
            MarkdownDocumentFrontmatterType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = MarkdownDocumentOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        title = d.pop("title")

        content = d.pop("content")

        tags = cast(list[str], d.pop("tags"))

        visibility = MarkdownDocumentVisibility(d.pop("visibility"))

        stage = MarkdownDocumentStage(d.pop("stage"))

        kind = MarkdownDocumentKind(d.pop("kind"))

        content_hash = d.pop("content_hash")

        size_bytes = d.pop("size_bytes")

        current_version = d.pop("current_version")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: MarkdownDocumentAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = MarkdownDocumentAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        def _parse_frontmatter(data: object) -> MarkdownDocumentFrontmatterType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                frontmatter_type_0 = MarkdownDocumentFrontmatterType0.from_dict(data)

                return frontmatter_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(MarkdownDocumentFrontmatterType0 | None | Unset, data)

        frontmatter = _parse_frontmatter(d.pop("frontmatter", UNSET))

        def _parse_category(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        category = _parse_category(d.pop("category", UNSET))

        def _parse_public_route(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        public_route = _parse_public_route(d.pop("public_route", UNSET))

        def _parse_latest_version_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        latest_version_id = _parse_latest_version_id(d.pop("latest_version_id", UNSET))

        object_ = cast(Literal["paper"] | Unset, d.pop("object", UNSET))
        if object_ != "paper" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'paper', got '{object_}'")

        get_v1_papers_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            title=title,
            content=content,
            tags=tags,
            visibility=visibility,
            stage=stage,
            kind=kind,
            content_hash=content_hash,
            size_bytes=size_bytes,
            current_version=current_version,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            author_kind=author_kind,
            author_id=author_id,
            deleted_at=deleted_at,
            frontmatter=frontmatter,
            category=category,
            public_route=public_route,
            latest_version_id=latest_version_id,
            object_=object_,
        )

        get_v1_papers_by_id_response_200.additional_properties = d
        return get_v1_papers_by_id_response_200

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
