from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.access_assignment_subject_kind import AccessAssignmentSubjectKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="AccessAssignment")


@_attrs_define
class AccessAssignment:
    """
    Attributes:
        id (str):
        subject_kind (AccessAssignmentSubjectKind):
        subject_id (str):
        scope_feature (str): '' = workspace-wide
        scope_item_id (str): '' = workspace-wide
        role_id (str):
        role_slug (str | Unset):
        role_name (str | Unset):
        granted_by (None | str | Unset):
        granted_at (str | Unset):
    """

    id: str
    subject_kind: AccessAssignmentSubjectKind
    subject_id: str
    scope_feature: str
    scope_item_id: str
    role_id: str
    role_slug: str | Unset = UNSET
    role_name: str | Unset = UNSET
    granted_by: None | str | Unset = UNSET
    granted_at: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        subject_kind = self.subject_kind.value

        subject_id = self.subject_id

        scope_feature = self.scope_feature

        scope_item_id = self.scope_item_id

        role_id = self.role_id

        role_slug = self.role_slug

        role_name = self.role_name

        granted_by: None | str | Unset
        if isinstance(self.granted_by, Unset):
            granted_by = UNSET
        else:
            granted_by = self.granted_by

        granted_at = self.granted_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "subject_kind": subject_kind,
                "subject_id": subject_id,
                "scope_feature": scope_feature,
                "scope_item_id": scope_item_id,
                "role_id": role_id,
            }
        )
        if role_slug is not UNSET:
            field_dict["role_slug"] = role_slug
        if role_name is not UNSET:
            field_dict["role_name"] = role_name
        if granted_by is not UNSET:
            field_dict["granted_by"] = granted_by
        if granted_at is not UNSET:
            field_dict["granted_at"] = granted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        subject_kind = AccessAssignmentSubjectKind(d.pop("subject_kind"))

        subject_id = d.pop("subject_id")

        scope_feature = d.pop("scope_feature")

        scope_item_id = d.pop("scope_item_id")

        role_id = d.pop("role_id")

        role_slug = d.pop("role_slug", UNSET)

        role_name = d.pop("role_name", UNSET)

        def _parse_granted_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        granted_by = _parse_granted_by(d.pop("granted_by", UNSET))

        granted_at = d.pop("granted_at", UNSET)

        access_assignment = cls(
            id=id,
            subject_kind=subject_kind,
            subject_id=subject_id,
            scope_feature=scope_feature,
            scope_item_id=scope_item_id,
            role_id=role_id,
            role_slug=role_slug,
            role_name=role_name,
            granted_by=granted_by,
            granted_at=granted_at,
        )

        access_assignment.additional_properties = d
        return access_assignment

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
