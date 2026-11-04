from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostDocumentVersionsBody")


@_attrs_define
class PostDocumentVersionsBody:
    """
    Attributes:
        document_id (str):
        name (str):
        pinned_op_id (str):
        pinned_sync_version (int):
        ecosystem_id (str | Unset):
        description (str | Unset):
    """

    document_id: str
    name: str
    pinned_op_id: str
    pinned_sync_version: int
    ecosystem_id: str | Unset = UNSET
    description: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        document_id = self.document_id

        name = self.name

        pinned_op_id = self.pinned_op_id

        pinned_sync_version = self.pinned_sync_version

        ecosystem_id = self.ecosystem_id

        description = self.description

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "documentId": document_id,
                "name": name,
                "pinnedOpId": pinned_op_id,
                "pinnedSyncVersion": pinned_sync_version,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        document_id = d.pop("documentId")

        name = d.pop("name")

        pinned_op_id = d.pop("pinnedOpId")

        pinned_sync_version = d.pop("pinnedSyncVersion")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        description = d.pop("description", UNSET)

        post_document_versions_body = cls(
            document_id=document_id,
            name=name,
            pinned_op_id=pinned_op_id,
            pinned_sync_version=pinned_sync_version,
            ecosystem_id=ecosystem_id,
            description=description,
        )

        return post_document_versions_body
