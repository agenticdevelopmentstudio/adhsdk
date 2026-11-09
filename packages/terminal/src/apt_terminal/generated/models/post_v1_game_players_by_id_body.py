from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamePlayersByIdBody")


@_attrs_define
class PostV1GamePlayersByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        game_id (str | Unset):
        character_avatar_url (None | str | Unset):
        visibility (str | Unset):
        first_played_at (str | Unset):
        last_played_at (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    game_id: str | Unset = UNSET
    character_avatar_url: None | str | Unset = UNSET
    visibility: str | Unset = UNSET
    first_played_at: str | Unset = UNSET
    last_played_at: str | Unset = UNSET

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

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if character_avatar_url is not UNSET:
            field_dict["character_avatar_url"] = character_avatar_url
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if first_played_at is not UNSET:
            field_dict["first_played_at"] = first_played_at
        if last_played_at is not UNSET:
            field_dict["last_played_at"] = last_played_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        game_id = d.pop("game_id", UNSET)

        def _parse_character_avatar_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        character_avatar_url = _parse_character_avatar_url(d.pop("character_avatar_url", UNSET))

        visibility = d.pop("visibility", UNSET)

        first_played_at = d.pop("first_played_at", UNSET)

        last_played_at = d.pop("last_played_at", UNSET)

        post_v1_game_players_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            character_avatar_url=character_avatar_url,
            visibility=visibility,
            first_played_at=first_played_at,
            last_played_at=last_played_at,
        )

        return post_v1_game_players_by_id_body
