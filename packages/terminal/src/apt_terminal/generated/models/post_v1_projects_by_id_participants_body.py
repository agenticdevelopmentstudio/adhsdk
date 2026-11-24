from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_projects_by_id_participants_body_participant_kind import (
    PostV1ProjectsByIdParticipantsBodyParticipantKind,
)

T = TypeVar("T", bound="PostV1ProjectsByIdParticipantsBody")


@_attrs_define
class PostV1ProjectsByIdParticipantsBody:
    """
    Attributes:
        participant_kind (PostV1ProjectsByIdParticipantsBodyParticipantKind):
        participant_id (str):
    """

    participant_kind: PostV1ProjectsByIdParticipantsBodyParticipantKind
    participant_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        participant_kind = self.participant_kind.value

        participant_id = self.participant_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "participant_kind": participant_kind,
                "participant_id": participant_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        participant_kind = PostV1ProjectsByIdParticipantsBodyParticipantKind(
            d.pop("participant_kind")
        )

        participant_id = d.pop("participant_id")

        post_v1_projects_by_id_participants_body = cls(
            participant_kind=participant_kind,
            participant_id=participant_id,
        )

        post_v1_projects_by_id_participants_body.additional_properties = d
        return post_v1_projects_by_id_participants_body

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
