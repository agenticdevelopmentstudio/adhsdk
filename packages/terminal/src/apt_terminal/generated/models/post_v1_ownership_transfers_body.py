from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_ownership_transfers_body_entity_type import (
    PostV1OwnershipTransfersBodyEntityType,
)
from ..models.post_v1_ownership_transfers_body_target_kind import (
    PostV1OwnershipTransfersBodyTargetKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1OwnershipTransfersBody")


@_attrs_define
class PostV1OwnershipTransfersBody:
    """
    Attributes:
        entity_type (PostV1OwnershipTransfersBodyEntityType): a transferable entity type, from the server’s
            TRANSFER_PLANS registry
        entity_id (str): the object’s rdid or uuid
        target (str): destination workspace slug (or ecosystem rdid, per the entity)
        target_kind (PostV1OwnershipTransfersBodyTargetKind | Unset): the namespace `target` names, when the client
            knows it
    """

    entity_type: PostV1OwnershipTransfersBodyEntityType
    entity_id: str
    target: str
    target_kind: PostV1OwnershipTransfersBodyTargetKind | Unset = UNSET
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
                "entity_type": entity_type,
                "entity_id": entity_id,
                "target": target,
            }
        )
        if target_kind is not UNSET:
            field_dict["target_kind"] = target_kind

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        entity_type = PostV1OwnershipTransfersBodyEntityType(d.pop("entity_type"))

        entity_id = d.pop("entity_id")

        target = d.pop("target")

        _target_kind = d.pop("target_kind", UNSET)
        target_kind: PostV1OwnershipTransfersBodyTargetKind | Unset
        if isinstance(_target_kind, Unset):
            target_kind = UNSET
        else:
            target_kind = PostV1OwnershipTransfersBodyTargetKind(_target_kind)

        post_v1_ownership_transfers_body = cls(
            entity_type=entity_type,
            entity_id=entity_id,
            target=target,
            target_kind=target_kind,
        )

        post_v1_ownership_transfers_body.additional_properties = d
        return post_v1_ownership_transfers_body

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
