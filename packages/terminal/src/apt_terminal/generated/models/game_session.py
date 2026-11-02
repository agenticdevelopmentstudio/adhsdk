from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_session_actor_type import GameSessionActorType
from ..models.game_session_status import GameSessionStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_session_payload_type_0 import GameSessionPayloadType0


T = TypeVar("T", bound="GameSession")


@_attrs_define
class GameSession:
    """
    Attributes:
        id (str):
        game_id (str):
        kind (str):
        status (GameSessionStatus):
        actor_type (GameSessionActorType):
        started_at (str):
        chat_id (None | str | Unset):
        subject_artifact_id (None | str | Unset):
        payload (GameSessionPayloadType0 | None | Unset):
        ended_at (None | str | Unset):
    """

    id: str
    game_id: str
    kind: str
    status: GameSessionStatus
    actor_type: GameSessionActorType
    started_at: str
    chat_id: None | str | Unset = UNSET
    subject_artifact_id: None | str | Unset = UNSET
    payload: GameSessionPayloadType0 | None | Unset = UNSET
    ended_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_session_payload_type_0 import GameSessionPayloadType0

        id = self.id

        game_id = self.game_id

        kind = self.kind

        status = self.status.value

        actor_type = self.actor_type.value

        started_at = self.started_at

        chat_id: None | str | Unset
        if isinstance(self.chat_id, Unset):
            chat_id = UNSET
        else:
            chat_id = self.chat_id

        subject_artifact_id: None | str | Unset
        if isinstance(self.subject_artifact_id, Unset):
            subject_artifact_id = UNSET
        else:
            subject_artifact_id = self.subject_artifact_id

        payload: dict[str, Any] | None | Unset
        if isinstance(self.payload, Unset):
            payload = UNSET
        elif isinstance(self.payload, GameSessionPayloadType0):
            payload = self.payload.to_dict()
        else:
            payload = self.payload

        ended_at: None | str | Unset
        if isinstance(self.ended_at, Unset):
            ended_at = UNSET
        else:
            ended_at = self.ended_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "gameId": game_id,
                "kind": kind,
                "status": status,
                "actorType": actor_type,
                "startedAt": started_at,
            }
        )
        if chat_id is not UNSET:
            field_dict["chatId"] = chat_id
        if subject_artifact_id is not UNSET:
            field_dict["subjectArtifactId"] = subject_artifact_id
        if payload is not UNSET:
            field_dict["payload"] = payload
        if ended_at is not UNSET:
            field_dict["endedAt"] = ended_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_session_payload_type_0 import GameSessionPayloadType0

        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("gameId")

        kind = d.pop("kind")

        status = GameSessionStatus(d.pop("status"))

        actor_type = GameSessionActorType(d.pop("actorType"))

        started_at = d.pop("startedAt")

        def _parse_chat_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        chat_id = _parse_chat_id(d.pop("chatId", UNSET))

        def _parse_subject_artifact_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_artifact_id = _parse_subject_artifact_id(d.pop("subjectArtifactId", UNSET))

        def _parse_payload(data: object) -> GameSessionPayloadType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_0 = GameSessionPayloadType0.from_dict(data)

                return payload_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameSessionPayloadType0 | None | Unset, data)

        payload = _parse_payload(d.pop("payload", UNSET))

        def _parse_ended_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ended_at = _parse_ended_at(d.pop("endedAt", UNSET))

        game_session = cls(
            id=id,
            game_id=game_id,
            kind=kind,
            status=status,
            actor_type=actor_type,
            started_at=started_at,
            chat_id=chat_id,
            subject_artifact_id=subject_artifact_id,
            payload=payload,
            ended_at=ended_at,
        )

        game_session.additional_properties = d
        return game_session

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
