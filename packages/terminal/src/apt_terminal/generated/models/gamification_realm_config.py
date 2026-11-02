from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_realm_config_mode import GamificationRealmConfigMode
from ..models.gamification_realm_config_skin import GamificationRealmConfigSkin

if TYPE_CHECKING:
    from ..models.gamification_realm_config_surfaces import GamificationRealmConfigSurfaces
    from ..models.gamification_seasons_type_0 import GamificationSeasonsType0


T = TypeVar("T", bound="GamificationRealmConfig")


@_attrs_define
class GamificationRealmConfig:
    """
    Attributes:
        ecosystem_id (str):
        mode (GamificationRealmConfigMode): 'none' leaves telemetry flowing but suppresses awards/UI; 'gamification'
            turns on badges/levels/streaks/leaderboards; 'game' is a dedicated playable game, which brings gamification with
            it
        skin (GamificationRealmConfigSkin):
        surfaces (GamificationRealmConfigSurfaces): Per-surface toggles; a surface is ON unless set false
        seasons (GamificationSeasonsType0 | None):
        timezone (str): IANA timezone for the realm's day/streak boundary (Night Owl); defaults to 'UTC'
    """

    ecosystem_id: str
    mode: GamificationRealmConfigMode
    skin: GamificationRealmConfigSkin
    surfaces: GamificationRealmConfigSurfaces
    seasons: GamificationSeasonsType0 | None
    timezone: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.gamification_seasons_type_0 import GamificationSeasonsType0

        ecosystem_id = self.ecosystem_id

        mode = self.mode.value

        skin = self.skin.value

        surfaces = self.surfaces.to_dict()

        seasons: dict[str, Any] | None
        if isinstance(self.seasons, GamificationSeasonsType0):
            seasons = self.seasons.to_dict()
        else:
            seasons = self.seasons

        timezone = self.timezone

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystemId": ecosystem_id,
                "mode": mode,
                "skin": skin,
                "surfaces": surfaces,
                "seasons": seasons,
                "timezone": timezone,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_realm_config_surfaces import (
            GamificationRealmConfigSurfaces,
        )
        from ..models.gamification_seasons_type_0 import GamificationSeasonsType0

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId")

        mode = GamificationRealmConfigMode(d.pop("mode"))

        skin = GamificationRealmConfigSkin(d.pop("skin"))

        surfaces = GamificationRealmConfigSurfaces.from_dict(d.pop("surfaces"))

        def _parse_seasons(data: object) -> GamificationSeasonsType0 | None:
            if data is None:
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
            return cast(GamificationSeasonsType0 | None, data)

        seasons = _parse_seasons(d.pop("seasons"))

        timezone = d.pop("timezone")

        gamification_realm_config = cls(
            ecosystem_id=ecosystem_id,
            mode=mode,
            skin=skin,
            surfaces=surfaces,
            seasons=seasons,
            timezone=timezone,
        )

        gamification_realm_config.additional_properties = d
        return gamification_realm_config

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
