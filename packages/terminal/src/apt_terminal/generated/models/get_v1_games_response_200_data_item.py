from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_games_response_200_data_item_engine_config_type_1 import (
        GetV1GamesResponse200DataItemEngineConfigType1,
    )


T = TypeVar("T", bound="GetV1GamesResponse200DataItem")


@_attrs_define
class GetV1GamesResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        slug (str):
        name (str):
        description (None | str):
        engine (str):
        engine_config (bool | float | GetV1GamesResponse200DataItemEngineConfigType1 | list[Any] | None | str):
        character_names (str):
        status (str):
        event_log (str):
        event_retention_days (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['game'] | Unset):
    """

    id: str
    ecosystem_id: str
    slug: str
    name: str
    description: None | str
    engine: str
    engine_config: (
        bool | float | GetV1GamesResponse200DataItemEngineConfigType1 | list[Any] | None | str
    )
    character_names: str
    status: str
    event_log: str
    event_retention_days: int
    created: int
    updated: int
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["game"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_v1_games_response_200_data_item_engine_config_type_1 import (
            GetV1GamesResponse200DataItemEngineConfigType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        slug = self.slug

        name = self.name

        description: None | str
        description = self.description

        engine = self.engine

        engine_config: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.engine_config, GetV1GamesResponse200DataItemEngineConfigType1):
            engine_config = self.engine_config.to_dict()
        elif isinstance(self.engine_config, list):
            engine_config = self.engine_config

        else:
            engine_config = self.engine_config

        character_names = self.character_names

        status = self.status

        event_log = self.event_log

        event_retention_days = self.event_retention_days

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
                "slug": slug,
                "name": name,
                "description": description,
                "engine": engine,
                "engine_config": engine_config,
                "character_names": character_names,
                "status": status,
                "event_log": event_log,
                "event_retention_days": event_retention_days,
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
        from ..models.get_v1_games_response_200_data_item_engine_config_type_1 import (
            GetV1GamesResponse200DataItemEngineConfigType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

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
        ) -> bool | float | GetV1GamesResponse200DataItemEngineConfigType1 | list[Any] | None | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                engine_config_type_1 = GetV1GamesResponse200DataItemEngineConfigType1.from_dict(
                    data
                )

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
                | GetV1GamesResponse200DataItemEngineConfigType1
                | list[Any]
                | None
                | str,
                data,
            )

        engine_config = _parse_engine_config(d.pop("engine_config"))

        character_names = d.pop("character_names")

        status = d.pop("status")

        event_log = d.pop("event_log")

        event_retention_days = d.pop("event_retention_days")

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

        object_ = cast(Literal["game"] | Unset, d.pop("object", UNSET))
        if object_ != "game" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game', got '{object_}'")

        get_v1_games_response_200_data_item = cls(
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
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_games_response_200_data_item
