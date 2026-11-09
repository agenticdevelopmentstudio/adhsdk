from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_realm_config import GamificationRealmConfig
    from ..models.gamification_replay_result import GamificationReplayResult


T = TypeVar("T", bound="PostV1GamificationConfigResponse200")


@_attrs_define
class PostV1GamificationConfigResponse200:
    """
    Attributes:
        config (GamificationRealmConfig):
        replayed (GamificationReplayResult | Unset):
        object_ (Literal['gamification.config'] | Unset):
    """

    config: GamificationRealmConfig
    replayed: GamificationReplayResult | Unset = UNSET
    object_: Literal["gamification.config"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        config = self.config.to_dict()

        replayed: dict[str, Any] | Unset = UNSET
        if not isinstance(self.replayed, Unset):
            replayed = self.replayed.to_dict()

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "config": config,
            }
        )
        if replayed is not UNSET:
            field_dict["replayed"] = replayed
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["gamification.config"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.config" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.config', got '{object_}'")

        post_v1_gamification_config_response_200 = cls(
            config=config,
            replayed=replayed,
            object_=object_,
        )

        post_v1_gamification_config_response_200.additional_properties = d
        return post_v1_gamification_config_response_200

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
