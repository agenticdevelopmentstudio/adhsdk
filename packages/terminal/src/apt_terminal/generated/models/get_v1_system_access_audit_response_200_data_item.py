from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1SystemAccessAuditResponse200DataItem")


@_attrs_define
class GetV1SystemAccessAuditResponse200DataItem:
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
        object_ (Literal['system.access_audit'] | Unset):
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
    object_: Literal["system.access_audit"] | Unset = UNSET
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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "actor_kind": actor_kind,
                "actor_id": actor_id,
                "actor_email": actor_email,
                "action": action,
                "subject_kind": subject_kind,
                "subject_id": subject_id,
                "target_feature": target_feature,
                "target_item_id": target_item_id,
                "role_id": role_id,
                "before": before,
                "after": after,
                "at": at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        actor_kind = d.pop("actor_kind")

        actor_id = d.pop("actor_id")

        def _parse_actor_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_email = _parse_actor_email(d.pop("actor_email"))

        action = d.pop("action")

        def _parse_subject_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_kind = _parse_subject_kind(d.pop("subject_kind"))

        def _parse_subject_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_id = _parse_subject_id(d.pop("subject_id"))

        def _parse_target_feature(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        target_feature = _parse_target_feature(d.pop("target_feature"))

        def _parse_target_item_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        target_item_id = _parse_target_item_id(d.pop("target_item_id"))

        def _parse_role_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        role_id = _parse_role_id(d.pop("role_id"))

        before = d.pop("before")

        after = d.pop("after")

        at = d.pop("at")

        object_ = cast(Literal["system.access_audit"] | Unset, d.pop("object", UNSET))
        if object_ != "system.access_audit" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'system.access_audit', got '{object_}'")

        get_v1_system_access_audit_response_200_data_item = cls(
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
            object_=object_,
        )

        get_v1_system_access_audit_response_200_data_item.additional_properties = d
        return get_v1_system_access_audit_response_200_data_item

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
