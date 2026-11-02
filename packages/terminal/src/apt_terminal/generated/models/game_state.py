from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.game_ref import GameRef
    from ..models.game_state_game_state import GameStateGameState
    from ..models.game_state_state import GameStateState


T = TypeVar("T", bound="GameState")


@_attrs_define
class GameState:
    """
    Attributes:
        game (GameRef):
        state (GameStateState):
        game_state (GameStateGameState):
        has_profile (bool):
    """

    game: GameRef
    state: GameStateState
    game_state: GameStateGameState
    has_profile: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        game = self.game.to_dict()

        state = self.state.to_dict()

        game_state = self.game_state.to_dict()

        has_profile = self.has_profile

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "game": game,
                "state": state,
                "gameState": game_state,
                "hasProfile": has_profile,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_ref import GameRef
        from ..models.game_state_game_state import GameStateGameState
        from ..models.game_state_state import GameStateState

        d = dict(src_dict)
        game = GameRef.from_dict(d.pop("game"))

        state = GameStateState.from_dict(d.pop("state"))

        game_state = GameStateGameState.from_dict(d.pop("gameState"))

        has_profile = d.pop("hasProfile")

        game_state = cls(
            game=game,
            state=state,
            game_state=game_state,
            has_profile=has_profile,
        )

        game_state.additional_properties = d
        return game_state

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
