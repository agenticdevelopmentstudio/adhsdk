from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostGameEffectsBody")


@_attrs_define
class PostGameEffectsBody:
    """
    Attributes:
        game_id (str):
        definition_id (str):
        key (str):
        trigger (str):
        target (str):
        operation (str):
        value (int):
        ecosystem_id (str | Unset):
        duration (int | None | Unset):
        sort_order (int | Unset):
    """

    game_id: str
    definition_id: str
    key: str
    trigger: str
    target: str
    operation: str
    value: int
    ecosystem_id: str | Unset = UNSET
    duration: int | None | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        game_id = self.game_id

        definition_id = self.definition_id

        key = self.key

        trigger = self.trigger

        target = self.target

        operation = self.operation

        value = self.value

        ecosystem_id = self.ecosystem_id

        duration: int | None | Unset
        if isinstance(self.duration, Unset):
            duration = UNSET
        else:
            duration = self.duration

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "gameId": game_id,
                "definitionId": definition_id,
                "key": key,
                "trigger": trigger,
                "target": target,
                "operation": operation,
                "value": value,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if duration is not UNSET:
            field_dict["duration"] = duration
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        game_id = d.pop("gameId")

        definition_id = d.pop("definitionId")

        key = d.pop("key")

        trigger = d.pop("trigger")

        target = d.pop("target")

        operation = d.pop("operation")

        value = d.pop("value")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_duration(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        duration = _parse_duration(d.pop("duration", UNSET))

        sort_order = d.pop("sortOrder", UNSET)

        post_game_effects_body = cls(
            game_id=game_id,
            definition_id=definition_id,
            key=key,
            trigger=trigger,
            target=target,
            operation=operation,
            value=value,
            ecosystem_id=ecosystem_id,
            duration=duration,
            sort_order=sort_order,
        )

        return post_game_effects_body
