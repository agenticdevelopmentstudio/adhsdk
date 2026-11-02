from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_game_games_body_engine_config_type_1 import (
        PostGameGamesBodyEngineConfigType1,
    )


T = TypeVar("T", bound="PostGameGamesBody")


@_attrs_define
class PostGameGamesBody:
    """
    Attributes:
        slug (str):
        name (str):
        engine (str):
        ecosystem_id (str | Unset):
        description (None | str | Unset):
        engine_config (bool | float | list[Any] | None | PostGameGamesBodyEngineConfigType1 | str | Unset):
        character_names (str | Unset):
        status (str | Unset):
        event_log (str | Unset):
        event_retention_days (int | Unset):
        sync_txid (int | Unset):
    """

    slug: str
    name: str
    engine: str
    ecosystem_id: str | Unset = UNSET
    description: None | str | Unset = UNSET
    engine_config: (
        bool | float | list[Any] | None | PostGameGamesBodyEngineConfigType1 | str | Unset
    ) = UNSET
    character_names: str | Unset = UNSET
    status: str | Unset = UNSET
    event_log: str | Unset = UNSET
    event_retention_days: int | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_game_games_body_engine_config_type_1 import (
            PostGameGamesBodyEngineConfigType1,
        )

        slug = self.slug

        name = self.name

        engine = self.engine

        ecosystem_id = self.ecosystem_id

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        engine_config: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.engine_config, Unset):
            engine_config = UNSET
        elif isinstance(self.engine_config, PostGameGamesBodyEngineConfigType1):
            engine_config = self.engine_config.to_dict()
        elif isinstance(self.engine_config, list):
            engine_config = self.engine_config

        else:
            engine_config = self.engine_config

        character_names = self.character_names

        status = self.status

        event_log = self.event_log

        event_retention_days = self.event_retention_days

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "engine": engine,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if description is not UNSET:
            field_dict["description"] = description
        if engine_config is not UNSET:
            field_dict["engineConfig"] = engine_config
        if character_names is not UNSET:
            field_dict["characterNames"] = character_names
        if status is not UNSET:
            field_dict["status"] = status
        if event_log is not UNSET:
            field_dict["eventLog"] = event_log
        if event_retention_days is not UNSET:
            field_dict["eventRetentionDays"] = event_retention_days
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_game_games_body_engine_config_type_1 import (
            PostGameGamesBodyEngineConfigType1,
        )

        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        engine = d.pop("engine")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_engine_config(
            data: object,
        ) -> bool | float | list[Any] | None | PostGameGamesBodyEngineConfigType1 | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                engine_config_type_1 = PostGameGamesBodyEngineConfigType1.from_dict(data)

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
                bool | float | list[Any] | None | PostGameGamesBodyEngineConfigType1 | str | Unset,
                data,
            )

        engine_config = _parse_engine_config(d.pop("engineConfig", UNSET))

        character_names = d.pop("characterNames", UNSET)

        status = d.pop("status", UNSET)

        event_log = d.pop("eventLog", UNSET)

        event_retention_days = d.pop("eventRetentionDays", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        post_game_games_body = cls(
            slug=slug,
            name=name,
            engine=engine,
            ecosystem_id=ecosystem_id,
            description=description,
            engine_config=engine_config,
            character_names=character_names,
            status=status,
            event_log=event_log,
            event_retention_days=event_retention_days,
            sync_txid=sync_txid,
        )

        return post_game_games_body
