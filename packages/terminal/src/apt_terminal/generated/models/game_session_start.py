from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GameSessionStart")


@_attrs_define
class GameSessionStart:
    """Exactly one of `game_id` / `slug` names the game. `chat_id` makes the call a resume.

    Attributes:
        kind (str):
        game_id (str | Unset):
        slug (str | Unset):
        chat_id (str | Unset):
        subject_artifact_id (str | Unset):
    """

    kind: str
    game_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    chat_id: str | Unset = UNSET
    subject_artifact_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind

        game_id = self.game_id

        slug = self.slug

        chat_id = self.chat_id

        subject_artifact_id = self.subject_artifact_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
            }
        )
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if chat_id is not UNSET:
            field_dict["chat_id"] = chat_id
        if subject_artifact_id is not UNSET:
            field_dict["subject_artifact_id"] = subject_artifact_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = d.pop("kind")

        game_id = d.pop("game_id", UNSET)

        slug = d.pop("slug", UNSET)

        chat_id = d.pop("chat_id", UNSET)

        subject_artifact_id = d.pop("subject_artifact_id", UNSET)

        game_session_start = cls(
            kind=kind,
            game_id=game_id,
            slug=slug,
            chat_id=chat_id,
            subject_artifact_id=subject_artifact_id,
        )

        game_session_start.additional_properties = d
        return game_session_start

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
