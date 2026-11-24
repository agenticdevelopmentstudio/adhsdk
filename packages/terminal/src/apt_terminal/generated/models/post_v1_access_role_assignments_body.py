from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_access_role_assignments_body_subject_kind import (
    PostV1AccessRoleAssignmentsBodySubjectKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccessRoleAssignmentsBody")


@_attrs_define
class PostV1AccessRoleAssignmentsBody:
    """
    Attributes:
        subject_kind (PostV1AccessRoleAssignmentsBodySubjectKind):
        subject_id (str):
        role_id (str):
        feature (str | Unset): with itemId: scope the grant to one item
        item_id (str | Unset):
    """

    subject_kind: PostV1AccessRoleAssignmentsBodySubjectKind
    subject_id: str
    role_id: str
    feature: str | Unset = UNSET
    item_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_kind = self.subject_kind.value

        subject_id = self.subject_id

        role_id = self.role_id

        feature = self.feature

        item_id = self.item_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_kind": subject_kind,
                "subject_id": subject_id,
                "role_id": role_id,
            }
        )
        if feature is not UNSET:
            field_dict["feature"] = feature
        if item_id is not UNSET:
            field_dict["item_id"] = item_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subject_kind = PostV1AccessRoleAssignmentsBodySubjectKind(d.pop("subject_kind"))

        subject_id = d.pop("subject_id")

        role_id = d.pop("role_id")

        feature = d.pop("feature", UNSET)

        item_id = d.pop("item_id", UNSET)

        post_v1_access_role_assignments_body = cls(
            subject_kind=subject_kind,
            subject_id=subject_id,
            role_id=role_id,
            feature=feature,
            item_id=item_id,
        )

        post_v1_access_role_assignments_body.additional_properties = d
        return post_v1_access_role_assignments_body

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
