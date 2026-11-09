from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_player_visibility import GamePlayerVisibility
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1GamePlayersMeResponse200")


@_attrs_define
class GetV1GamePlayersMeResponse200:
    """
    Attributes:
        id (str):
        game_id (str):
        visibility (GamePlayerVisibility):
        first_played_at (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        character_name (None | str | Unset):
        character_avatar_url (None | str | Unset):
        last_played_at (None | str | Unset):
        object_ (Literal['game.player'] | Unset):
    """

    id: str
    game_id: str
    visibility: GamePlayerVisibility
    first_played_at: str
    created: int
    updated: int
    character_name: None | str | Unset = UNSET
    character_avatar_url: None | str | Unset = UNSET
    last_played_at: None | str | Unset = UNSET
    object_: Literal["game.player"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        game_id = self.game_id

        visibility = self.visibility.value

        first_played_at = self.first_played_at

        created = self.created

        updated = self.updated

        character_name: None | str | Unset
        if isinstance(self.character_name, Unset):
            character_name = UNSET
        else:
            character_name = self.character_name

        character_avatar_url: None | str | Unset
        if isinstance(self.character_avatar_url, Unset):
            character_avatar_url = UNSET
        else:
            character_avatar_url = self.character_avatar_url

        last_played_at: None | str | Unset
        if isinstance(self.last_played_at, Unset):
            last_played_at = UNSET
        else:
            last_played_at = self.last_played_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "game_id": game_id,
                "visibility": visibility,
                "first_played_at": first_played_at,
                "created": created,
                "updated": updated,
            }
        )
        if character_name is not UNSET:
            field_dict["character_name"] = character_name
        if character_avatar_url is not UNSET:
            field_dict["character_avatar_url"] = character_avatar_url
        if last_played_at is not UNSET:
            field_dict["last_played_at"] = last_played_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("game_id")

        visibility = GamePlayerVisibility(d.pop("visibility"))

        first_played_at = d.pop("first_played_at")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_character_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        character_name = _parse_character_name(d.pop("character_name", UNSET))

        def _parse_character_avatar_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        character_avatar_url = _parse_character_avatar_url(d.pop("character_avatar_url", UNSET))

        def _parse_last_played_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_played_at = _parse_last_played_at(d.pop("last_played_at", UNSET))

        object_ = cast(Literal["game.player"] | Unset, d.pop("object", UNSET))
        if object_ != "game.player" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.player', got '{object_}'")

        get_v1_game_players_me_response_200 = cls(
            id=id,
            game_id=game_id,
            visibility=visibility,
            first_played_at=first_played_at,
            created=created,
            updated=updated,
            character_name=character_name,
            character_avatar_url=character_avatar_url,
            last_played_at=last_played_at,
            object_=object_,
        )

        get_v1_game_players_me_response_200.additional_properties = d
        return get_v1_game_players_me_response_200

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
