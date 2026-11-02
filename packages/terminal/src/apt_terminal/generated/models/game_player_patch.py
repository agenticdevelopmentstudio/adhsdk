from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_player_patch_visibility import GamePlayerPatchVisibility
from ..types import UNSET, Unset

T = TypeVar("T", bound="GamePlayerPatch")


@_attrs_define
class GamePlayerPatch:
    """Omit a key to leave it alone; send `null` to clear it. `character_name` is screened whenever it is set, whatever the
    profile’s visibility.

        Attributes:
            game_id (str | Unset):
            slug (str | Unset):
            character_name (None | str | Unset):
            character_avatar_url (None | str | Unset):
            visibility (GamePlayerPatchVisibility | Unset):
    """

    game_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    character_name: None | str | Unset = UNSET
    character_avatar_url: None | str | Unset = UNSET
    visibility: GamePlayerPatchVisibility | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        game_id = self.game_id

        slug = self.slug

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

        visibility: str | Unset = UNSET
        if not isinstance(self.visibility, Unset):
            visibility = self.visibility.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if character_name is not UNSET:
            field_dict["character_name"] = character_name
        if character_avatar_url is not UNSET:
            field_dict["character_avatar_url"] = character_avatar_url
        if visibility is not UNSET:
            field_dict["visibility"] = visibility

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        game_id = d.pop("game_id", UNSET)

        slug = d.pop("slug", UNSET)

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

        _visibility = d.pop("visibility", UNSET)
        visibility: GamePlayerPatchVisibility | Unset
        if isinstance(_visibility, Unset):
            visibility = UNSET
        else:
            visibility = GamePlayerPatchVisibility(_visibility)

        game_player_patch = cls(
            game_id=game_id,
            slug=slug,
            character_name=character_name,
            character_avatar_url=character_avatar_url,
            visibility=visibility,
        )

        game_player_patch.additional_properties = d
        return game_player_patch

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
