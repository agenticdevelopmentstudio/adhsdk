from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_realm_config import GamificationRealmConfig
    from ..models.gamification_replay_result import GamificationReplayResult


T = TypeVar("T", bound="GamificationRealmConfigUpdate")


@_attrs_define
class GamificationRealmConfigUpdate:
    """
    Attributes:
        config (GamificationRealmConfig):
        replayed (GamificationReplayResult | Unset):
    """

    config: GamificationRealmConfig
    replayed: GamificationReplayResult | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        config = self.config.to_dict()

        replayed: dict[str, Any] | Unset = UNSET
        if not isinstance(self.replayed, Unset):
            replayed = self.replayed.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "config": config,
            }
        )
        if replayed is not UNSET:
            field_dict["replayed"] = replayed

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_realm_config import GamificationRealmConfig
        from ..models.gamification_replay_result import GamificationReplayResult

        d = dict(src_dict)
        config = GamificationRealmConfig.from_dict(d.pop("config"))

        _replayed = d.pop("replayed", UNSET)
        replayed: GamificationReplayResult | Unset
        if isinstance(_replayed, Unset):
            replayed = UNSET
        else:
            replayed = GamificationReplayResult.from_dict(_replayed)

        gamification_realm_config_update = cls(
            config=config,
            replayed=replayed,
        )

        gamification_realm_config_update.additional_properties = d
        return gamification_realm_config_update

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
