from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.feed_item_author_kind import FeedItemAuthorKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="FeedItem")


@_attrs_define
class FeedItem:
    """
    Attributes:
        id (str):
        owner_kind (str): Kind of principal that owns the feed item: 'customer', 'organization', 'application',
            'persona' or 'ecosystem'.
        owner_id (str): Id of the owning principal.
        ecosystem_id (str):
        source (str):
        entity_type (str):
        action (str):
        summary (str):
        is_read (bool):
        created (int): Unix timestamp, in seconds.
        author_kind (FeedItemAuthorKind | Unset): Kind of principal that wrote the item; null when nobody did (a storage
            token).
        author_id (None | str | Unset): Id of that principal.
        deleted_at (None | str | Unset):
        entity_id (None | str | Unset):
        actor_id (None | str | Unset):
        metadata (None | str | Unset):
    """

    id: str
    owner_kind: str
    owner_id: str
    ecosystem_id: str
    source: str
    entity_type: str
    action: str
    summary: str
    is_read: bool
    created: int
    author_kind: FeedItemAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    entity_id: None | str | Unset = UNSET
    actor_id: None | str | Unset = UNSET
    metadata: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        ecosystem_id = self.ecosystem_id

        source = self.source

        entity_type = self.entity_type

        action = self.action

        summary = self.summary

        is_read = self.is_read

        created = self.created

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

        entity_id: None | str | Unset
        if isinstance(self.entity_id, Unset):
            entity_id = UNSET
        else:
            entity_id = self.entity_id

        actor_id: None | str | Unset
        if isinstance(self.actor_id, Unset):
            actor_id = UNSET
        else:
            actor_id = self.actor_id

        metadata: None | str | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        else:
            metadata = self.metadata

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "ecosystem_id": ecosystem_id,
                "source": source,
                "entity_type": entity_type,
                "action": action,
                "summary": summary,
                "is_read": is_read,
                "created": created,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if entity_id is not UNSET:
            field_dict["entity_id"] = entity_id
        if actor_id is not UNSET:
            field_dict["actor_id"] = actor_id
        if metadata is not UNSET:
            field_dict["metadata"] = metadata

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        ecosystem_id = d.pop("ecosystem_id")

        source = d.pop("source")

        entity_type = d.pop("entity_type")

        action = d.pop("action")

        summary = d.pop("summary")

        is_read = d.pop("is_read")

        created = d.pop("created")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: FeedItemAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = FeedItemAuthorKind(_author_kind)

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

        def _parse_entity_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        entity_id = _parse_entity_id(d.pop("entity_id", UNSET))

        def _parse_actor_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        actor_id = _parse_actor_id(d.pop("actor_id", UNSET))

        def _parse_metadata(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        feed_item = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            ecosystem_id=ecosystem_id,
            source=source,
            entity_type=entity_type,
            action=action,
            summary=summary,
            is_read=is_read,
            created=created,
            author_kind=author_kind,
            author_id=author_id,
            deleted_at=deleted_at,
            entity_id=entity_id,
            actor_id=actor_id,
            metadata=metadata,
        )

        feed_item.additional_properties = d
        return feed_item

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
