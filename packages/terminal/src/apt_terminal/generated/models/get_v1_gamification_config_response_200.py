from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_realm_config_mode import GamificationRealmConfigMode
from ..models.gamification_realm_config_skin import GamificationRealmConfigSkin
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_realm_config_surfaces import GamificationRealmConfigSurfaces
    from ..models.gamification_seasons_type_0 import GamificationSeasonsType0


T = TypeVar("T", bound="GetV1GamificationConfigResponse200")


@_attrs_define
class GetV1GamificationConfigResponse200:
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
        object_ (Literal['gamification.config'] | Unset):
    """

    ecosystem_id: str
    mode: GamificationRealmConfigMode
    skin: GamificationRealmConfigSkin
    surfaces: GamificationRealmConfigSurfaces
    seasons: GamificationSeasonsType0 | None
    timezone: str
    object_: Literal["gamification.config"] | Unset = UNSET
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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem_id": ecosystem_id,
                "mode": mode,
                "skin": skin,
                "surfaces": surfaces,
                "seasons": seasons,
                "timezone": timezone,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_realm_config_surfaces import (
            GamificationRealmConfigSurfaces,
        )
        from ..models.gamification_seasons_type_0 import GamificationSeasonsType0

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id")

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

        object_ = cast(Literal["gamification.config"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.config" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.config', got '{object_}'")

        get_v1_gamification_config_response_200 = cls(
            ecosystem_id=ecosystem_id,
            mode=mode,
            skin=skin,
            surfaces=surfaces,
            seasons=seasons,
            timezone=timezone,
            object_=object_,
        )

        get_v1_gamification_config_response_200.additional_properties = d
        return get_v1_gamification_config_response_200

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
