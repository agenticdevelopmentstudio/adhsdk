from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_paper_search_hit_kind import PublicPaperSearchHitKind

if TYPE_CHECKING:
    from ..models.public_paper_search_hit_author import PublicPaperSearchHitAuthor


T = TypeVar("T", bound="PublicPaperSearchHit")


@_attrs_define
class PublicPaperSearchHit:
    """
    Attributes:
        id (str):
        title (str):
        kind (PublicPaperSearchHitKind): Document kind: 'paper' (ordinary) or 'research' (AI-ingested).
        public_route (str): Published route slug; link as /public/users/{author.slug}/papers/{publicRoute}.
        author (PublicPaperSearchHitAuthor):
        category (None | str):
        tags (list[str]):
        summary (None | str): Display summary read from the doc frontmatter (jsonb), or null.
        evaluation (None | str): Display evaluation read from the doc frontmatter (jsonb), or null.
        snippet (str): ~200-char match-context excerpt around the first q hit (head of content when q is empty/absent).
        created_at (str):
        updated_at (str):
    """

    id: str
    title: str
    kind: PublicPaperSearchHitKind
    public_route: str
    author: PublicPaperSearchHitAuthor
    category: None | str
    tags: list[str]
    summary: None | str
    evaluation: None | str
    snippet: str
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        title = self.title

        kind = self.kind.value

        public_route = self.public_route

        author = self.author.to_dict()

        category: None | str
        category = self.category

        tags = self.tags

        summary: None | str
        summary = self.summary

        evaluation: None | str
        evaluation = self.evaluation

        snippet = self.snippet

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "title": title,
                "kind": kind,
                "publicRoute": public_route,
                "author": author,
                "category": category,
                "tags": tags,
                "summary": summary,
                "evaluation": evaluation,
                "snippet": snippet,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_paper_search_hit_author import (
            PublicPaperSearchHitAuthor,
        )

        d = dict(src_dict)
        id = d.pop("id")

        title = d.pop("title")

        kind = PublicPaperSearchHitKind(d.pop("kind"))

        public_route = d.pop("publicRoute")

        author = PublicPaperSearchHitAuthor.from_dict(d.pop("author"))

        def _parse_category(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        category = _parse_category(d.pop("category"))

        tags = cast(list[str], d.pop("tags"))

        def _parse_summary(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        summary = _parse_summary(d.pop("summary"))

        def _parse_evaluation(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        evaluation = _parse_evaluation(d.pop("evaluation"))

        snippet = d.pop("snippet")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        public_paper_search_hit = cls(
            id=id,
            title=title,
            kind=kind,
            public_route=public_route,
            author=author,
            category=category,
            tags=tags,
            summary=summary,
            evaluation=evaluation,
            snippet=snippet,
            created_at=created_at,
            updated_at=updated_at,
        )

        public_paper_search_hit.additional_properties = d
        return public_paper_search_hit

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
