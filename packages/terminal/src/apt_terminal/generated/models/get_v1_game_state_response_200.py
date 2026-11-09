from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_ref import GameRef
    from ..models.game_state_game_state import GameStateGameState
    from ..models.game_state_state import GameStateState


T = TypeVar("T", bound="GetV1GameStateResponse200")


@_attrs_define
class GetV1GameStateResponse200:
    """
    Attributes:
        game (GameRef):
        state (GameStateState):
        game_state (GameStateGameState):
        has_profile (bool):
        object_ (Literal['game.state'] | Unset):
    """

    game: GameRef
    state: GameStateState
    game_state: GameStateGameState
    has_profile: bool
    object_: Literal["game.state"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        game = self.game.to_dict()

        state = self.state.to_dict()

        game_state = self.game_state.to_dict()

        has_profile = self.has_profile

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "game": game,
                "state": state,
                "game_state": game_state,
                "has_profile": has_profile,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_ref import GameRef
        from ..models.game_state_game_state import GameStateGameState
        from ..models.game_state_state import GameStateState

        d = dict(src_dict)
        game = GameRef.from_dict(d.pop("game"))

        state = GameStateState.from_dict(d.pop("state"))

        game_state = GameStateGameState.from_dict(d.pop("game_state"))

        has_profile = d.pop("has_profile")

        object_ = cast(Literal["game.state"] | Unset, d.pop("object", UNSET))
        if object_ != "game.state" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.state', got '{object_}'")

        get_v1_game_state_response_200 = cls(
            game=game,
            state=state,
            game_state=game_state,
            has_profile=has_profile,
            object_=object_,
        )

        get_v1_game_state_response_200.additional_properties = d
        return get_v1_game_state_response_200

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
