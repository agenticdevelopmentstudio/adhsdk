from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_gamification_config_body_mode import PostV1GamificationConfigBodyMode
from ..models.post_v1_gamification_config_body_skin import PostV1GamificationConfigBodySkin
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_seasons_type_0 import GamificationSeasonsType0
    from ..models.post_v1_gamification_config_body_surfaces import (
        PostV1GamificationConfigBodySurfaces,
    )


T = TypeVar("T", bound="PostV1GamificationConfigBody")


@_attrs_define
class PostV1GamificationConfigBody:
    """
    Attributes:
        ecosystem (str): Scopes the call; the caller passes it as a parameter, not in the path.
        mode (PostV1GamificationConfigBodyMode | Unset):
        skin (PostV1GamificationConfigBodySkin | Unset):
        surfaces (PostV1GamificationConfigBodySurfaces | Unset):
        seasons (GamificationSeasonsType0 | None | Unset):
        timezone (str | Unset): IANA zone for the realm's day/streak boundary
    """

    ecosystem: str
    mode: PostV1GamificationConfigBodyMode | Unset = UNSET
    skin: PostV1GamificationConfigBodySkin | Unset = UNSET
    surfaces: PostV1GamificationConfigBodySurfaces | Unset = UNSET
    seasons: GamificationSeasonsType0 | None | Unset = UNSET
    timezone: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.gamification_seasons_type_0 import GamificationSeasonsType0

        ecosystem = self.ecosystem

        mode: str | Unset = UNSET
        if not isinstance(self.mode, Unset):
            mode = self.mode.value

        skin: str | Unset = UNSET
        if not isinstance(self.skin, Unset):
            skin = self.skin.value

        surfaces: dict[str, Any] | Unset = UNSET
        if not isinstance(self.surfaces, Unset):
            surfaces = self.surfaces.to_dict()

        seasons: dict[str, Any] | None | Unset
        if isinstance(self.seasons, Unset):
            seasons = UNSET
        elif isinstance(self.seasons, GamificationSeasonsType0):
            seasons = self.seasons.to_dict()
        else:
            seasons = self.seasons

        timezone = self.timezone

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem": ecosystem,
            }
        )
        if mode is not UNSET:
            field_dict["mode"] = mode
        if skin is not UNSET:
            field_dict["skin"] = skin
        if surfaces is not UNSET:
            field_dict["surfaces"] = surfaces
        if seasons is not UNSET:
            field_dict["seasons"] = seasons
        if timezone is not UNSET:
            field_dict["timezone"] = timezone

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_seasons_type_0 import GamificationSeasonsType0
        from ..models.post_v1_gamification_config_body_surfaces import (
            PostV1GamificationConfigBodySurfaces,
        )

        d = dict(src_dict)
        ecosystem = d.pop("ecosystem")

        _mode = d.pop("mode", UNSET)
        mode: PostV1GamificationConfigBodyMode | Unset
        if isinstance(_mode, Unset):
            mode = UNSET
        else:
            mode = PostV1GamificationConfigBodyMode(_mode)

        _skin = d.pop("skin", UNSET)
        skin: PostV1GamificationConfigBodySkin | Unset
        if isinstance(_skin, Unset):
            skin = UNSET
        else:
            skin = PostV1GamificationConfigBodySkin(_skin)

        _surfaces = d.pop("surfaces", UNSET)
        surfaces: PostV1GamificationConfigBodySurfaces | Unset
        if isinstance(_surfaces, Unset):
            surfaces = UNSET
        else:
            surfaces = PostV1GamificationConfigBodySurfaces.from_dict(_surfaces)

        def _parse_seasons(data: object) -> GamificationSeasonsType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_gamification_seasons_type_0 = GamificationSeasonsType0.from_dict(
                    data
                )

                return componentsschemas_gamification_seasons_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GamificationSeasonsType0 | None | Unset, data)

        seasons = _parse_seasons(d.pop("seasons", UNSET))

        timezone = d.pop("timezone", UNSET)

        post_v1_gamification_config_body = cls(
            ecosystem=ecosystem,
            mode=mode,
            skin=skin,
            surfaces=surfaces,
            seasons=seasons,
            timezone=timezone,
        )

        post_v1_gamification_config_body.additional_properties = d
        return post_v1_gamification_config_body

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
