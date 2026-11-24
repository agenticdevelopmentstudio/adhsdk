from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamePlayersBody")


@_attrs_define
class PostV1GamePlayersBody:
    """
    Attributes:
        game_id (str):
        first_played_at (str):
        last_played_at (str):
        ecosystem_id (str | Unset):
        character_avatar_url (None | str | Unset):
        visibility (str | Unset):
    """

    game_id: str
    first_played_at: str
    last_played_at: str
    ecosystem_id: str | Unset = UNSET
    character_avatar_url: None | str | Unset = UNSET
    visibility: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        game_id = self.game_id

        first_played_at = self.first_played_at

        last_played_at = self.last_played_at

        ecosystem_id = self.ecosystem_id

        character_avatar_url: None | str | Unset
        if isinstance(self.character_avatar_url, Unset):
            character_avatar_url = UNSET
        else:
            character_avatar_url = self.character_avatar_url

        visibility = self.visibility

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "game_id": game_id,
                "first_played_at": first_played_at,
                "last_played_at": last_played_at,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if character_avatar_url is not UNSET:
            field_dict["character_avatar_url"] = character_avatar_url
        if visibility is not UNSET:
            field_dict["visibility"] = visibility

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        game_id = d.pop("game_id")

        first_played_at = d.pop("first_played_at")

        last_played_at = d.pop("last_played_at")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_character_avatar_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        character_avatar_url = _parse_character_avatar_url(d.pop("character_avatar_url", UNSET))

        visibility = d.pop("visibility", UNSET)

        post_v1_game_players_body = cls(
            game_id=game_id,
            first_played_at=first_played_at,
            last_played_at=last_played_at,
            ecosystem_id=ecosystem_id,
            character_avatar_url=character_avatar_url,
            visibility=visibility,
        )

        return post_v1_game_players_body
