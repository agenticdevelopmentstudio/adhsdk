from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GameEffectsByIdBody")


@_attrs_define
class PostV1GameEffectsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        game_id (str | Unset):
        definition_id (str | Unset):
        key (str | Unset):
        trigger (str | Unset):
        target (str | Unset):
        operation (str | Unset):
        value (int | Unset):
        duration (int | None | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    game_id: str | Unset = UNSET
    definition_id: str | Unset = UNSET
    key: str | Unset = UNSET
    trigger: str | Unset = UNSET
    target: str | Unset = UNSET
    operation: str | Unset = UNSET
    value: int | Unset = UNSET
    duration: int | None | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        definition_id = self.definition_id

        key = self.key

        trigger = self.trigger

        target = self.target

        operation = self.operation

        value = self.value

        duration: int | None | Unset
        if isinstance(self.duration, Unset):
            duration = UNSET
        else:
            duration = self.duration

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if definition_id is not UNSET:
            field_dict["definition_id"] = definition_id
        if key is not UNSET:
            field_dict["key"] = key
        if trigger is not UNSET:
            field_dict["trigger"] = trigger
        if target is not UNSET:
            field_dict["target"] = target
        if operation is not UNSET:
            field_dict["operation"] = operation
        if value is not UNSET:
            field_dict["value"] = value
        if duration is not UNSET:
            field_dict["duration"] = duration
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        game_id = d.pop("game_id", UNSET)

        definition_id = d.pop("definition_id", UNSET)

        key = d.pop("key", UNSET)

        trigger = d.pop("trigger", UNSET)

        target = d.pop("target", UNSET)

        operation = d.pop("operation", UNSET)

        value = d.pop("value", UNSET)

        def _parse_duration(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        duration = _parse_duration(d.pop("duration", UNSET))

        sort_order = d.pop("sort_order", UNSET)

        post_v1_game_effects_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            definition_id=definition_id,
            key=key,
            trigger=trigger,
            target=target,
            operation=operation,
            value=value,
            duration=duration,
            sort_order=sort_order,
        )

        return post_v1_game_effects_by_id_body
