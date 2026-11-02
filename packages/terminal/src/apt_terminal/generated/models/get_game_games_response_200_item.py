from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_game_games_response_200_item_engine_config_type_1 import (
        GetGameGamesResponse200ItemEngineConfigType1,
    )


T = TypeVar("T", bound="GetGameGamesResponse200Item")


@_attrs_define
class GetGameGamesResponse200Item:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        slug (str):
        name (str):
        description (None | str):
        engine (str):
        engine_config (bool | float | GetGameGamesResponse200ItemEngineConfigType1 | list[Any] | None | str):
        character_names (str):
        status (str):
        event_log (str):
        event_retention_days (int):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    slug: str
    name: str
    description: None | str
    engine: str
    engine_config: (
        bool | float | GetGameGamesResponse200ItemEngineConfigType1 | list[Any] | None | str
    )
    character_names: str
    status: str
    event_log: str
    event_retention_days: int
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_game_games_response_200_item_engine_config_type_1 import (
            GetGameGamesResponse200ItemEngineConfigType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        slug = self.slug

        name = self.name

        description: None | str
        description = self.description

        engine = self.engine

        engine_config: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.engine_config, GetGameGamesResponse200ItemEngineConfigType1):
            engine_config = self.engine_config.to_dict()
        elif isinstance(self.engine_config, list):
            engine_config = self.engine_config

        else:
            engine_config = self.engine_config

        character_names = self.character_names

        status = self.status

        event_log = self.event_log

        event_retention_days = self.event_retention_days

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
                "slug": slug,
                "name": name,
                "description": description,
                "engine": engine,
                "engineConfig": engine_config,
                "characterNames": character_names,
                "status": status,
                "eventLog": event_log,
                "eventRetentionDays": event_retention_days,
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
        from ..models.get_game_games_response_200_item_engine_config_type_1 import (
            GetGameGamesResponse200ItemEngineConfigType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        engine = d.pop("engine")

        def _parse_engine_config(
            data: object,
        ) -> bool | float | GetGameGamesResponse200ItemEngineConfigType1 | list[Any] | None | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                engine_config_type_1 = GetGameGamesResponse200ItemEngineConfigType1.from_dict(data)

                return engine_config_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                engine_config_type_2 = cast(list[Any], data)

                return engine_config_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | GetGameGamesResponse200ItemEngineConfigType1
                | list[Any]
                | None
                | str,
                data,
            )

        engine_config = _parse_engine_config(d.pop("engineConfig"))

        character_names = d.pop("characterNames")

        status = d.pop("status")

        event_log = d.pop("eventLog")

        event_retention_days = d.pop("eventRetentionDays")

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

        get_game_games_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            slug=slug,
            name=name,
            description=description,
            engine=engine,
            engine_config=engine_config,
            character_names=character_names,
            status=status,
            event_log=event_log,
            event_retention_days=event_retention_days,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_game_games_response_200_item
