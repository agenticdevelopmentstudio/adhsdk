from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.markdown_document_summary_kind import MarkdownDocumentSummaryKind
from ..models.markdown_document_summary_stage import MarkdownDocumentSummaryStage
from ..models.markdown_document_summary_visibility import MarkdownDocumentSummaryVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.markdown_document_summary_frontmatter_type_0 import (
        MarkdownDocumentSummaryFrontmatterType0,
    )


T = TypeVar("T", bound="MarkdownDocumentSummary")


@_attrs_define
class MarkdownDocumentSummary:
    """
    Attributes:
        id (str):
        title (str): Server-derived, read-only: the frontmatter `title` then `name`, else the first non-empty line of
            the body (frontmatter and code fences ignored, leading markdown syntax stripped), else 'Untitled'. Capped at 500
            characters.
        excerpt (str): Server-derived, read-only preview: up to 4 body lines FOLLOWING the title line, newline-
            separated, each capped at 160 characters and stripped of leading markdown syntax. Empty when the body holds
            nothing past its title. Exists because this projection carries no `content` — it is what lets a list render a
            preview without fetching every document whole.
        tags (list[str]):
        visibility (MarkdownDocumentSummaryVisibility):
        stage (MarkdownDocumentSummaryStage):
        kind (MarkdownDocumentSummaryKind):
        content_hash (str):
        size_bytes (int):
        current_version (int):
        created_at (str):
        updated_at (str):
        frontmatter (MarkdownDocumentSummaryFrontmatterType0 | None | Unset):
        category (None | str | Unset):
        public_route (None | str | Unset):
        latest_version_id (None | str | Unset):
    """

    id: str
    title: str
    excerpt: str
    tags: list[str]
    visibility: MarkdownDocumentSummaryVisibility
    stage: MarkdownDocumentSummaryStage
    kind: MarkdownDocumentSummaryKind
    content_hash: str
    size_bytes: int
    current_version: int
    created_at: str
    updated_at: str
    frontmatter: MarkdownDocumentSummaryFrontmatterType0 | None | Unset = UNSET
    category: None | str | Unset = UNSET
    public_route: None | str | Unset = UNSET
    latest_version_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.markdown_document_summary_frontmatter_type_0 import (
            MarkdownDocumentSummaryFrontmatterType0,
        )

        id = self.id

        title = self.title

        excerpt = self.excerpt

        tags = self.tags

        visibility = self.visibility.value

        stage = self.stage.value

        kind = self.kind.value

        content_hash = self.content_hash

        size_bytes = self.size_bytes

        current_version = self.current_version

        created_at = self.created_at

        updated_at = self.updated_at

        frontmatter: dict[str, Any] | None | Unset
        if isinstance(self.frontmatter, Unset):
            frontmatter = UNSET
        elif isinstance(self.frontmatter, MarkdownDocumentSummaryFrontmatterType0):
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

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "title": title,
                "excerpt": excerpt,
                "tags": tags,
                "visibility": visibility,
                "stage": stage,
                "kind": kind,
                "contentHash": content_hash,
                "sizeBytes": size_bytes,
                "currentVersion": current_version,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if frontmatter is not UNSET:
            field_dict["frontmatter"] = frontmatter
        if category is not UNSET:
            field_dict["category"] = category
        if public_route is not UNSET:
            field_dict["publicRoute"] = public_route
        if latest_version_id is not UNSET:
            field_dict["latestVersionId"] = latest_version_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.markdown_document_summary_frontmatter_type_0 import (
            MarkdownDocumentSummaryFrontmatterType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        title = d.pop("title")

        excerpt = d.pop("excerpt")

        tags = cast(list[str], d.pop("tags"))

        visibility = MarkdownDocumentSummaryVisibility(d.pop("visibility"))

        stage = MarkdownDocumentSummaryStage(d.pop("stage"))

        kind = MarkdownDocumentSummaryKind(d.pop("kind"))

        content_hash = d.pop("contentHash")

        size_bytes = d.pop("sizeBytes")

        current_version = d.pop("currentVersion")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_frontmatter(
            data: object,
        ) -> MarkdownDocumentSummaryFrontmatterType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                frontmatter_type_0 = MarkdownDocumentSummaryFrontmatterType0.from_dict(data)

                return frontmatter_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(MarkdownDocumentSummaryFrontmatterType0 | None | Unset, data)

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

        public_route = _parse_public_route(d.pop("publicRoute", UNSET))

        def _parse_latest_version_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        latest_version_id = _parse_latest_version_id(d.pop("latestVersionId", UNSET))

        markdown_document_summary = cls(
            id=id,
            title=title,
            excerpt=excerpt,
            tags=tags,
            visibility=visibility,
            stage=stage,
            kind=kind,
            content_hash=content_hash,
            size_bytes=size_bytes,
            current_version=current_version,
            created_at=created_at,
            updated_at=updated_at,
            frontmatter=frontmatter,
            category=category,
            public_route=public_route,
            latest_version_id=latest_version_id,
        )

        markdown_document_summary.additional_properties = d
        return markdown_document_summary

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
