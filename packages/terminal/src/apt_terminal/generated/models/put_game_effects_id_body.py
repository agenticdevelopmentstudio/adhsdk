from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutGameEffectsIdBody")


@_attrs_define
class PutGameEffectsIdBody:
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
        sync_txid (int | Unset):
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
    sync_txid: int | Unset = UNSET

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

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if game_id is not UNSET:
            field_dict["gameId"] = game_id
        if definition_id is not UNSET:
            field_dict["definitionId"] = definition_id
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
            field_dict["sortOrder"] = sort_order
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        game_id = d.pop("gameId", UNSET)

        definition_id = d.pop("definitionId", UNSET)

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

        sort_order = d.pop("sortOrder", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        put_game_effects_id_body = cls(
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
            sync_txid=sync_txid,
        )

        return put_game_effects_id_body
