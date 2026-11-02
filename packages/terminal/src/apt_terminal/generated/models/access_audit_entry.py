from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AccessAuditEntry")


@_attrs_define
class AccessAuditEntry:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
        actor_kind (str):
        actor_id (str):
        actor_email (None | str):
        action (str):
        subject_kind (None | str):
        subject_id (None | str):
        target_feature (None | str):
        target_item_id (None | str):
        role_id (None | str):
        before (Any): Pre-change state (action-shaped)
        after (Any): Post-change state (action-shaped)
        at (str):
    """

    id: str
    owner_kind: str
    owner_id: str
    actor_kind: str
    actor_id: str
    actor_email: None | str
    action: str
    subject_kind: None | str
    subject_id: None | str
    target_feature: None | str
    target_item_id: None | str
    role_id: None | str
    before: Any
    after: Any
    at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        actor_kind = self.actor_kind

        actor_id = self.actor_id

        actor_email: None | str
        actor_email = self.actor_email

        action = self.action

        subject_kind: None | str
        subject_kind = self.subject_kind

        subject_id: None | str
        subject_id = self.subject_id

        target_feature: None | str
        target_feature = self.target_feature

        target_item_id: None | str
        target_item_id = self.target_item_id

        role_id: None | str
        role_id = self.role_id

        before = self.before

        after = self.after

        at = self.at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "actorKind": actor_kind,
                "actorId": actor_id,
                "actorEmail": actor_email,
                "action": action,
                "subjectKind": subject_kind,
                "subjectId": subject_id,
                "targetFeature": target_feature,
                "targetItemId": target_item_id,
                "roleId": role_id,
                "before": before,
                "after": after,
                "at": at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        actor_kind = d.pop("actorKind")

        actor_id = d.pop("actorId")

        def _parse_actor_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_email = _parse_actor_email(d.pop("actorEmail"))

        action = d.pop("action")

        def _parse_subject_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_kind = _parse_subject_kind(d.pop("subjectKind"))

        def _parse_subject_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_id = _parse_subject_id(d.pop("subjectId"))

        def _parse_target_feature(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        target_feature = _parse_target_feature(d.pop("targetFeature"))

        def _parse_target_item_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        target_item_id = _parse_target_item_id(d.pop("targetItemId"))

        def _parse_role_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        role_id = _parse_role_id(d.pop("roleId"))

        before = d.pop("before")

        after = d.pop("after")

        at = d.pop("at")

        access_audit_entry = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            actor_kind=actor_kind,
            actor_id=actor_id,
            actor_email=actor_email,
            action=action,
            subject_kind=subject_kind,
            subject_id=subject_id,
            target_feature=target_feature,
            target_item_id=target_item_id,
            role_id=role_id,
            before=before,
            after=after,
            at=at,
        )

        access_audit_entry.additional_properties = d
        return access_audit_entry

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
