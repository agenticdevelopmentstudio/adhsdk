from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsBookmarksBody")


@_attrs_define
class PostV1IntegrationsBookmarksBody:
    """
    Attributes:
        connection_id (str):
        external_id (str):
        source_provider (str):
        title (str):
        url (str):
        ecosystem_id (str | Unset):
        excerpt (None | str | Unset):
        note (None | str | Unset):
        tags (None | str | Unset):
        image_url (None | str | Unset):
        collection_id (None | str | Unset):
        collection_name (None | str | Unset):
        is_favorite (bool | Unset):
        external_created_at (None | str | Unset):
    """

    connection_id: str
    external_id: str
    source_provider: str
    title: str
    url: str
    ecosystem_id: str | Unset = UNSET
    excerpt: None | str | Unset = UNSET
    note: None | str | Unset = UNSET
    tags: None | str | Unset = UNSET
    image_url: None | str | Unset = UNSET
    collection_id: None | str | Unset = UNSET
    collection_name: None | str | Unset = UNSET
    is_favorite: bool | Unset = UNSET
    external_created_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        connection_id = self.connection_id

        external_id = self.external_id

        source_provider = self.source_provider

        title = self.title

        url = self.url

        ecosystem_id = self.ecosystem_id

        excerpt: None | str | Unset
        if isinstance(self.excerpt, Unset):
            excerpt = UNSET
        else:
            excerpt = self.excerpt

        note: None | str | Unset
        if isinstance(self.note, Unset):
            note = UNSET
        else:
            note = self.note

        tags: None | str | Unset
        if isinstance(self.tags, Unset):
            tags = UNSET
        else:
            tags = self.tags

        image_url: None | str | Unset
        if isinstance(self.image_url, Unset):
            image_url = UNSET
        else:
            image_url = self.image_url

        collection_id: None | str | Unset
        if isinstance(self.collection_id, Unset):
            collection_id = UNSET
        else:
            collection_id = self.collection_id

        collection_name: None | str | Unset
        if isinstance(self.collection_name, Unset):
            collection_name = UNSET
        else:
            collection_name = self.collection_name

        is_favorite = self.is_favorite

        external_created_at: None | str | Unset
        if isinstance(self.external_created_at, Unset):
            external_created_at = UNSET
        else:
            external_created_at = self.external_created_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "connection_id": connection_id,
                "external_id": external_id,
                "source_provider": source_provider,
                "title": title,
                "url": url,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if excerpt is not UNSET:
            field_dict["excerpt"] = excerpt
        if note is not UNSET:
            field_dict["note"] = note
        if tags is not UNSET:
            field_dict["tags"] = tags
        if image_url is not UNSET:
            field_dict["image_url"] = image_url
        if collection_id is not UNSET:
            field_dict["collection_id"] = collection_id
        if collection_name is not UNSET:
            field_dict["collection_name"] = collection_name
        if is_favorite is not UNSET:
            field_dict["is_favorite"] = is_favorite
        if external_created_at is not UNSET:
            field_dict["external_created_at"] = external_created_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        connection_id = d.pop("connection_id")

        external_id = d.pop("external_id")

        source_provider = d.pop("source_provider")

        title = d.pop("title")

        url = d.pop("url")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_excerpt(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        excerpt = _parse_excerpt(d.pop("excerpt", UNSET))

        def _parse_note(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        note = _parse_note(d.pop("note", UNSET))

        def _parse_tags(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        tags = _parse_tags(d.pop("tags", UNSET))

        def _parse_image_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        image_url = _parse_image_url(d.pop("image_url", UNSET))

        def _parse_collection_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        collection_id = _parse_collection_id(d.pop("collection_id", UNSET))

        def _parse_collection_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        collection_name = _parse_collection_name(d.pop("collection_name", UNSET))

        is_favorite = d.pop("is_favorite", UNSET)

        def _parse_external_created_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_created_at = _parse_external_created_at(d.pop("external_created_at", UNSET))

        post_v1_integrations_bookmarks_body = cls(
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            title=title,
            url=url,
            ecosystem_id=ecosystem_id,
            excerpt=excerpt,
            note=note,
            tags=tags,
            image_url=image_url,
            collection_id=collection_id,
            collection_name=collection_name,
            is_favorite=is_favorite,
            external_created_at=external_created_at,
        )

        return post_v1_integrations_bookmarks_body
