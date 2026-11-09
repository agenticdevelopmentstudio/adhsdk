from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.chat_live_event_state import ChatLiveEventState
from ..types import UNSET, Unset

T = TypeVar("T", bound="ChatLiveEvent")


@_attrs_define
class ChatLiveEvent:
    """The `data` of an event on GET /chat/stream. Which fields are present depends on the SSE event name (see the route);
    every chat event carries `chatId`.

        Attributes:
            chat_id (str | Unset):
            seq (int | Unset): `message`, `message_updated`
            participant_id (str | Unset): `typing`
            state (ChatLiveEventState | Unset): `typing`
            expires_at (str | Unset): `typing` — ISO time the indicator lapses
            added (list[str] | Unset): `participants_changed` (participant ids), `chats_changed` (chat ids)
            removed (list[str] | Unset): `participants_changed` (participant ids), `chats_changed` (chat ids)
            chat_ids (list[str] | Unset): `ready`
    """

    chat_id: str | Unset = UNSET
    seq: int | Unset = UNSET
    participant_id: str | Unset = UNSET
    state: ChatLiveEventState | Unset = UNSET
    expires_at: str | Unset = UNSET
    added: list[str] | Unset = UNSET
    removed: list[str] | Unset = UNSET
    chat_ids: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chat_id = self.chat_id

        seq = self.seq

        participant_id = self.participant_id

        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        expires_at = self.expires_at

        added: list[str] | Unset = UNSET
        if not isinstance(self.added, Unset):
            added = self.added

        removed: list[str] | Unset = UNSET
        if not isinstance(self.removed, Unset):
            removed = self.removed

        chat_ids: list[str] | Unset = UNSET
        if not isinstance(self.chat_ids, Unset):
            chat_ids = self.chat_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if chat_id is not UNSET:
            field_dict["chat_id"] = chat_id
        if seq is not UNSET:
            field_dict["seq"] = seq
        if participant_id is not UNSET:
            field_dict["participant_id"] = participant_id
        if state is not UNSET:
            field_dict["state"] = state
        if expires_at is not UNSET:
            field_dict["expires_at"] = expires_at
        if added is not UNSET:
            field_dict["added"] = added
        if removed is not UNSET:
            field_dict["removed"] = removed
        if chat_ids is not UNSET:
            field_dict["chat_ids"] = chat_ids

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        chat_id = d.pop("chat_id", UNSET)

        seq = d.pop("seq", UNSET)

        participant_id = d.pop("participant_id", UNSET)

        _state = d.pop("state", UNSET)
        state: ChatLiveEventState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = ChatLiveEventState(_state)

        expires_at = d.pop("expires_at", UNSET)

        added = cast(list[str], d.pop("added", UNSET))

        removed = cast(list[str], d.pop("removed", UNSET))

        chat_ids = cast(list[str], d.pop("chat_ids", UNSET))

        chat_live_event = cls(
            chat_id=chat_id,
            seq=seq,
            participant_id=participant_id,
            state=state,
            expires_at=expires_at,
            added=added,
            removed=removed,
            chat_ids=chat_ids,
        )

        chat_live_event.additional_properties = d
        return chat_live_event

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
