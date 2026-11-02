from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_ownership_transfer_body_entity_type import PostOwnershipTransferBodyEntityType
from ..models.post_ownership_transfer_body_target_kind import PostOwnershipTransferBodyTargetKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostOwnershipTransferBody")


@_attrs_define
class PostOwnershipTransferBody:
    """
    Attributes:
        entity_type (PostOwnershipTransferBodyEntityType): a transferable entity type, from the server’s TRANSFER_PLANS
            registry
        entity_id (str): the object’s rdid or uuid
        target (str): destination workspace slug (or ecosystem rdid, per the entity)
        target_kind (PostOwnershipTransferBodyTargetKind | Unset): the namespace `target` names, when the client knows
            it
    """

    entity_type: PostOwnershipTransferBodyEntityType
    entity_id: str
    target: str
    target_kind: PostOwnershipTransferBodyTargetKind | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        entity_type = self.entity_type.value

        entity_id = self.entity_id

        target = self.target

        target_kind: str | Unset = UNSET
        if not isinstance(self.target_kind, Unset):
            target_kind = self.target_kind.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "entityType": entity_type,
                "entityId": entity_id,
                "target": target,
            }
        )
        if target_kind is not UNSET:
            field_dict["targetKind"] = target_kind

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        entity_type = PostOwnershipTransferBodyEntityType(d.pop("entityType"))

        entity_id = d.pop("entityId")

        target = d.pop("target")

        _target_kind = d.pop("targetKind", UNSET)
        target_kind: PostOwnershipTransferBodyTargetKind | Unset
        if isinstance(_target_kind, Unset):
            target_kind = UNSET
        else:
            target_kind = PostOwnershipTransferBodyTargetKind(_target_kind)

        post_ownership_transfer_body = cls(
            entity_type=entity_type,
            entity_id=entity_id,
            target=target,
            target_kind=target_kind,
        )

        post_ownership_transfer_body.additional_properties = d
        return post_ownership_transfer_body

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
