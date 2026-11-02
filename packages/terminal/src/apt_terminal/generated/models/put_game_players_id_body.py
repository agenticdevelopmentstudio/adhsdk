from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutGamePlayersIdBody")


@_attrs_define
class PutGamePlayersIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        game_id (str | Unset):
        character_avatar_url (None | str | Unset):
        visibility (str | Unset):
        first_played_at (str | Unset):
        last_played_at (str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    game_id: str | Unset = UNSET
    character_avatar_url: None | str | Unset = UNSET
    visibility: str | Unset = UNSET
    first_played_at: str | Unset = UNSET
    last_played_at: str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        character_avatar_url: None | str | Unset
        if isinstance(self.character_avatar_url, Unset):
            character_avatar_url = UNSET
        else:
            character_avatar_url = self.character_avatar_url

        visibility = self.visibility

        first_played_at = self.first_played_at

        last_played_at = self.last_played_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if game_id is not UNSET:
            field_dict["gameId"] = game_id
        if character_avatar_url is not UNSET:
            field_dict["characterAvatarUrl"] = character_avatar_url
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if first_played_at is not UNSET:
            field_dict["firstPlayedAt"] = first_played_at
        if last_played_at is not UNSET:
            field_dict["lastPlayedAt"] = last_played_at
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        game_id = d.pop("gameId", UNSET)

        def _parse_character_avatar_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        character_avatar_url = _parse_character_avatar_url(d.pop("characterAvatarUrl", UNSET))

        visibility = d.pop("visibility", UNSET)

        first_played_at = d.pop("firstPlayedAt", UNSET)

        last_played_at = d.pop("lastPlayedAt", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        put_game_players_id_body = cls(
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            character_avatar_url=character_avatar_url,
            visibility=visibility,
            first_played_at=first_played_at,
            last_played_at=last_played_at,
            sync_txid=sync_txid,
        )

        return put_game_players_id_body
