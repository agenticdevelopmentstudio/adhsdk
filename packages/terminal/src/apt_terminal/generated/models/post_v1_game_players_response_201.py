from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamePlayersResponse201")


@_attrs_define
class PostV1GamePlayersResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        game_id (str):
        character_name (None | str):
        character_avatar_url (None | str):
        visibility (str):
        first_played_at (str):
        last_played_at (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['game.player'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    game_id: str
    character_name: None | str
    character_avatar_url: None | str
    visibility: str
    first_played_at: str
    last_played_at: str
    created: int
    updated: int
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["game.player"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        game_id = self.game_id

        character_name: None | str
        character_name = self.character_name

        character_avatar_url: None | str
        character_avatar_url = self.character_avatar_url

        visibility = self.visibility

        first_played_at = self.first_played_at

        last_played_at = self.last_played_at

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
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "game_id": game_id,
                "character_name": character_name,
                "character_avatar_url": character_avatar_url,
                "visibility": visibility,
                "first_played_at": first_played_at,
                "last_played_at": last_played_at,
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

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        game_id = d.pop("game_id")

        def _parse_character_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        character_name = _parse_character_name(d.pop("character_name"))

        def _parse_character_avatar_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        character_avatar_url = _parse_character_avatar_url(d.pop("character_avatar_url"))

        visibility = d.pop("visibility")

        first_played_at = d.pop("first_played_at")

        last_played_at = d.pop("last_played_at")

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

        object_ = cast(Literal["game.player"] | Unset, d.pop("object", UNSET))
        if object_ != "game.player" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.player', got '{object_}'")

        post_v1_game_players_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            game_id=game_id,
            character_name=character_name,
            character_avatar_url=character_avatar_url,
            visibility=visibility,
            first_played_at=first_played_at,
            last_played_at=last_played_at,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_game_players_response_201
