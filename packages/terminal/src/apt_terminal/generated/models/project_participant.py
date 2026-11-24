from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_participant_participant_kind import ProjectParticipantParticipantKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="ProjectParticipant")


@_attrs_define
class ProjectParticipant:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        participant_kind (ProjectParticipantParticipantKind):
        participant_id (str): the attached actor id (opaque)
        role (str): the participant's project role (DB default 'member')
        added_at (str):
        added_by (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    participant_kind: ProjectParticipantParticipantKind
    participant_id: str
    role: str
    added_at: str
    added_by: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        participant_kind = self.participant_kind.value

        participant_id = self.participant_id

        role = self.role

        added_at = self.added_at

        added_by: None | str | Unset
        if isinstance(self.added_by, Unset):
            added_by = UNSET
        else:
            added_by = self.added_by

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "participant_kind": participant_kind,
                "participant_id": participant_id,
                "role": role,
                "added_at": added_at,
            }
        )
        if added_by is not UNSET:
            field_dict["added_by"] = added_by

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        participant_kind = ProjectParticipantParticipantKind(d.pop("participant_kind"))

        participant_id = d.pop("participant_id")

        role = d.pop("role")

        added_at = d.pop("added_at")

        def _parse_added_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        added_by = _parse_added_by(d.pop("added_by", UNSET))

        project_participant = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            participant_kind=participant_kind,
            participant_id=participant_id,
            role=role,
            added_at=added_at,
            added_by=added_by,
        )

        project_participant.additional_properties = d
        return project_participant

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
