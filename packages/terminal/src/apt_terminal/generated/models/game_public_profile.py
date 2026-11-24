from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_public_profile_visibility import GamePublicProfileVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_player_stat import GamePlayerStat
    from ..models.game_ref import GameRef


T = TypeVar("T", bound="GamePublicProfile")


@_attrs_define
class GamePublicProfile:
    """
    Attributes:
        game (GameRef):
        slug (str):
        visibility (GamePublicProfileVisibility):
        stats (list[GamePlayerStat]):
        name (None | str | Unset):
        character_name (None | str | Unset):
        character_avatar_url (None | str | Unset):
        first_played_at (str | Unset):
        last_played_at (None | str | Unset):
    """

    game: GameRef
    slug: str
    visibility: GamePublicProfileVisibility
    stats: list[GamePlayerStat]
    name: None | str | Unset = UNSET
    character_name: None | str | Unset = UNSET
    character_avatar_url: None | str | Unset = UNSET
    first_played_at: str | Unset = UNSET
    last_played_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        game = self.game.to_dict()

        slug = self.slug

        visibility = self.visibility.value

        stats = []
        for stats_item_data in self.stats:
            stats_item = stats_item_data.to_dict()
            stats.append(stats_item)

        name: None | str | Unset
        if isinstance(self.name, Unset):
            name = UNSET
        else:
            name = self.name

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

        first_played_at = self.first_played_at

        last_played_at: None | str | Unset
        if isinstance(self.last_played_at, Unset):
            last_played_at = UNSET
        else:
            last_played_at = self.last_played_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "game": game,
                "slug": slug,
                "visibility": visibility,
                "stats": stats,
            }
        )
        if name is not UNSET:
            field_dict["name"] = name
        if character_name is not UNSET:
            field_dict["character_name"] = character_name
        if character_avatar_url is not UNSET:
            field_dict["character_avatar_url"] = character_avatar_url
        if first_played_at is not UNSET:
            field_dict["first_played_at"] = first_played_at
        if last_played_at is not UNSET:
            field_dict["last_played_at"] = last_played_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_player_stat import GamePlayerStat
        from ..models.game_ref import GameRef

        d = dict(src_dict)
        game = GameRef.from_dict(d.pop("game"))

        slug = d.pop("slug")

        visibility = GamePublicProfileVisibility(d.pop("visibility"))

        stats = []
        _stats = d.pop("stats")
        for stats_item_data in _stats:
            stats_item = GamePlayerStat.from_dict(stats_item_data)

            stats.append(stats_item)

        def _parse_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        name = _parse_name(d.pop("name", UNSET))

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

        first_played_at = d.pop("first_played_at", UNSET)

        def _parse_last_played_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_played_at = _parse_last_played_at(d.pop("last_played_at", UNSET))

        game_public_profile = cls(
            game=game,
            slug=slug,
            visibility=visibility,
            stats=stats,
            name=name,
            character_name=character_name,
            character_avatar_url=character_avatar_url,
            first_played_at=first_played_at,
            last_played_at=last_played_at,
        )

        game_public_profile.additional_properties = d
        return game_public_profile

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
