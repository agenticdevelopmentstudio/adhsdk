from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_participant_participant_kind import ProjectParticipantParticipantKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ProjectsByIdParticipantsResponse200DataItem")


@_attrs_define
class GetV1ProjectsByIdParticipantsResponse200DataItem:
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
        object_ (Literal['participant'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    participant_kind: ProjectParticipantParticipantKind
    participant_id: str
    role: str
    added_at: str
    added_by: None | str | Unset = UNSET
    object_: Literal["participant"] | Unset = UNSET
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

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["participant"] | Unset, d.pop("object", UNSET))
        if object_ != "participant" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'participant', got '{object_}'")

        get_v1_projects_by_id_participants_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            participant_kind=participant_kind,
            participant_id=participant_id,
            role=role,
            added_at=added_at,
            added_by=added_by,
            object_=object_,
        )

        get_v1_projects_by_id_participants_response_200_data_item.additional_properties = d
        return get_v1_projects_by_id_participants_response_200_data_item

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
