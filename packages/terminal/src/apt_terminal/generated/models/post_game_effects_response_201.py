from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostGameEffectsResponse201")


@_attrs_define
class PostGameEffectsResponse201:
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
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
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
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

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

        created_at = self.created_at

        updated_at = self.updated_at

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "gameId": game_id,
                "definitionId": definition_id,
                "key": key,
                "trigger": trigger,
                "target": target,
                "operation": operation,
                "value": value,
                "duration": duration,
                "sortOrder": sort_order,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "deletedAt": deleted_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        game_id = d.pop("gameId")

        definition_id = d.pop("definitionId")

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

        sort_order = d.pop("sortOrder")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        post_game_effects_response_201 = cls(
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
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_game_effects_response_201
