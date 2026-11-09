from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentVersionsByIdBody")


@_attrs_define
class PostV1DocumentVersionsByIdBody:
    """
    Attributes:
        document_id (str | Unset):
        ecosystem_id (str | Unset):
        name (str | Unset):
        description (str | Unset):
        pinned_op_id (str | Unset):
        pinned_sync_version (int | Unset):
    """

    document_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    pinned_op_id: str | Unset = UNSET
    pinned_sync_version: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        document_id = self.document_id

        ecosystem_id = self.ecosystem_id

        name = self.name

        description = self.description

        pinned_op_id = self.pinned_op_id

        pinned_sync_version = self.pinned_sync_version

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if document_id is not UNSET:
            field_dict["document_id"] = document_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if pinned_op_id is not UNSET:
            field_dict["pinned_op_id"] = pinned_op_id
        if pinned_sync_version is not UNSET:
            field_dict["pinned_sync_version"] = pinned_sync_version

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        document_id = d.pop("document_id", UNSET)

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        pinned_op_id = d.pop("pinned_op_id", UNSET)

        pinned_sync_version = d.pop("pinned_sync_version", UNSET)

        post_v1_document_versions_by_id_body = cls(
            document_id=document_id,
            ecosystem_id=ecosystem_id,
            name=name,
            description=description,
            pinned_op_id=pinned_op_id,
            pinned_sync_version=pinned_sync_version,
        )

        return post_v1_document_versions_by_id_body
