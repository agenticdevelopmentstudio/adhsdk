from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GameEffectsResponse201")


@_attrs_define
class PostV1GameEffectsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        game_id (str):
        definition_id (str):
        key (str):
        trigger (str):
        target (str):
        operation (str):
        value (int):
        duration (int | None):
        sort_order (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['game.effect'] | Unset):
    """

    id: str
    ecosystem_id: str
    game_id: str
    definition_id: str
    key: str
    trigger: str
    target: str
    operation: str
    value: int
    duration: int | None
    sort_order: int
    created: int
    updated: int
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["game.effect"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        definition_id = self.definition_id

        key = self.key

        trigger = self.trigger

        target = self.target

        operation = self.operation

        value = self.value

        duration: int | None
        duration = self.duration

        sort_order = self.sort_order

        created = self.created

        updated = self.updated

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "game_id": game_id,
                "definition_id": definition_id,
                "key": key,
                "trigger": trigger,
                "target": target,
                "operation": operation,
                "value": value,
                "duration": duration,
                "sort_order": sort_order,
                "created": created,
                "updated": updated,
                "deleted_at": deleted_at,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        game_id = d.pop("game_id")

        definition_id = d.pop("definition_id")

        key = d.pop("key")

        trigger = d.pop("trigger")

        target = d.pop("target")

        operation = d.pop("operation")

        value = d.pop("value")

        def _parse_duration(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        duration = _parse_duration(d.pop("duration"))

        sort_order = d.pop("sort_order")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["game.effect"] | Unset, d.pop("object", UNSET))
        if object_ != "game.effect" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.effect', got '{object_}'")

        post_v1_game_effects_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            definition_id=definition_id,
            key=key,
            trigger=trigger,
            target=target,
            operation=operation,
            value=value,
            duration=duration,
            sort_order=sort_order,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_game_effects_response_201
