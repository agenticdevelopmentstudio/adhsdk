from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.storage_attachment_status import StorageAttachmentStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.storage_attachment_metadata_type_0 import StorageAttachmentMetadataType0


T = TypeVar("T", bound="StorageAttachment")


@_attrs_define
class StorageAttachment:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
        owner_type (str): e.g. 'standalone', 'chat_message', 'document'
        object_key (str): R2 object key the presigned URLs address.
        storage_kind (str): Backing store, e.g. 'r2'.
        filename (str):
        content_type (str):
        size_bytes (int):
        content_hash (str):
        status (StorageAttachmentStatus): 'pending' (presigned, awaiting upload) → 'ready' (bytes confirmed).
        created_at (str):
        updated_at (str):
        owner_id (None | str | Unset): Polymorphic domain owner (NOT the tenant).
        width (int | None | Unset):
        height (int | None | Unset):
        duration_ms (int | None | Unset):
        metadata (None | StorageAttachmentMetadataType0 | Unset): Caller-supplied JSON metadata (jsonb) — intentionally
            open.
        deleted_at (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    owner_type: str
    object_key: str
    storage_kind: str
    filename: str
    content_type: str
    size_bytes: int
    content_hash: str
    status: StorageAttachmentStatus
    created_at: str
    updated_at: str
    owner_id: None | str | Unset = UNSET
    width: int | None | Unset = UNSET
    height: int | None | Unset = UNSET
    duration_ms: int | None | Unset = UNSET
    metadata: None | StorageAttachmentMetadataType0 | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.storage_attachment_metadata_type_0 import (
            StorageAttachmentMetadataType0,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        owner_type = self.owner_type

        object_key = self.object_key

        storage_kind = self.storage_kind

        filename = self.filename

        content_type = self.content_type

        size_bytes = self.size_bytes

        content_hash = self.content_hash

        status = self.status.value

        created_at = self.created_at

        updated_at = self.updated_at

        owner_id: None | str | Unset
        if isinstance(self.owner_id, Unset):
            owner_id = UNSET
        else:
            owner_id = self.owner_id

        width: int | None | Unset
        if isinstance(self.width, Unset):
            width = UNSET
        else:
            width = self.width

        height: int | None | Unset
        if isinstance(self.height, Unset):
            height = UNSET
        else:
            height = self.height

        duration_ms: int | None | Unset
        if isinstance(self.duration_ms, Unset):
            duration_ms = UNSET
        else:
            duration_ms = self.duration_ms

        metadata: dict[str, Any] | None | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, StorageAttachmentMetadataType0):
            metadata = self.metadata.to_dict()
        else:
            metadata = self.metadata

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "customerId": customer_id,
                "ownerType": owner_type,
                "objectKey": object_key,
                "storageKind": storage_kind,
                "filename": filename,
                "contentType": content_type,
                "sizeBytes": size_bytes,
                "contentHash": content_hash,
                "status": status,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if width is not UNSET:
            field_dict["width"] = width
        if height is not UNSET:
            field_dict["height"] = height
        if duration_ms is not UNSET:
            field_dict["durationMs"] = duration_ms
        if metadata is not UNSET:
            field_dict["metadata"] = metadata
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.storage_attachment_metadata_type_0 import (
            StorageAttachmentMetadataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        owner_type = d.pop("ownerType")

        object_key = d.pop("objectKey")

        storage_kind = d.pop("storageKind")

        filename = d.pop("filename")

        content_type = d.pop("contentType")

        size_bytes = d.pop("sizeBytes")

        content_hash = d.pop("contentHash")

        status = StorageAttachmentStatus(d.pop("status"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_owner_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        owner_id = _parse_owner_id(d.pop("ownerId", UNSET))

        def _parse_width(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        width = _parse_width(d.pop("width", UNSET))

        def _parse_height(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        height = _parse_height(d.pop("height", UNSET))

        def _parse_duration_ms(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        duration_ms = _parse_duration_ms(d.pop("durationMs", UNSET))

        def _parse_metadata(data: object) -> None | StorageAttachmentMetadataType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0 = StorageAttachmentMetadataType0.from_dict(data)

                return metadata_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | StorageAttachmentMetadataType0 | Unset, data)

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        storage_attachment = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            owner_type=owner_type,
            object_key=object_key,
            storage_kind=storage_kind,
            filename=filename,
            content_type=content_type,
            size_bytes=size_bytes,
            content_hash=content_hash,
            status=status,
            created_at=created_at,
            updated_at=updated_at,
            owner_id=owner_id,
            width=width,
            height=height,
            duration_ms=duration_ms,
            metadata=metadata,
            deleted_at=deleted_at,
        )

        storage_attachment.additional_properties = d
        return storage_attachment

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
