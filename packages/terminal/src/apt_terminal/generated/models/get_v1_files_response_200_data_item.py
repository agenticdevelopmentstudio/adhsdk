from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.storage_attachment_status import StorageAttachmentStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.storage_attachment_metadata_type_0 import StorageAttachmentMetadataType0


T = TypeVar("T", bound="GetV1FilesResponse200DataItem")


@_attrs_define
class GetV1FilesResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str): Kind of principal that owns the attachment: 'customer', 'organization', 'application',
            'persona' or 'ecosystem'.
        owner_id (str): Id of the owning principal.
        parent_type (str): Kind of row the attachment hangs off, e.g. 'standalone', 'persona', 'registry.entry'.
        object_key (str): R2 object key the presigned URLs address.
        storage_kind (str): Backing store, e.g. 'r2'.
        filename (str):
        content_type (str):
        size_bytes (int):
        content_hash (str):
        status (StorageAttachmentStatus): 'pending' (presigned, awaiting upload) → 'ready' (bytes confirmed).
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        parent_id (None | str | Unset): Id of the row the attachment hangs off; null for a standalone attachment.
        width (int | None | Unset):
        height (int | None | Unset):
        duration_ms (int | None | Unset):
        metadata (None | StorageAttachmentMetadataType0 | Unset): Caller-supplied JSON metadata (jsonb) — intentionally
            open.
        deleted_at (None | str | Unset):
        object_ (Literal['file'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    parent_type: str
    object_key: str
    storage_kind: str
    filename: str
    content_type: str
    size_bytes: int
    content_hash: str
    status: StorageAttachmentStatus
    created: int
    updated: int
    parent_id: None | str | Unset = UNSET
    width: int | None | Unset = UNSET
    height: int | None | Unset = UNSET
    duration_ms: int | None | Unset = UNSET
    metadata: None | StorageAttachmentMetadataType0 | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    object_: Literal["file"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.storage_attachment_metadata_type_0 import (
            StorageAttachmentMetadataType0,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        parent_type = self.parent_type

        object_key = self.object_key

        storage_kind = self.storage_kind

        filename = self.filename

        content_type = self.content_type

        size_bytes = self.size_bytes

        content_hash = self.content_hash

        status = self.status.value

        created = self.created

        updated = self.updated

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "parent_type": parent_type,
                "object_key": object_key,
                "storage_kind": storage_kind,
                "filename": filename,
                "content_type": content_type,
                "size_bytes": size_bytes,
                "content_hash": content_hash,
                "status": status,
                "created": created,
                "updated": updated,
            }
        )
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if width is not UNSET:
            field_dict["width"] = width
        if height is not UNSET:
            field_dict["height"] = height
        if duration_ms is not UNSET:
            field_dict["duration_ms"] = duration_ms
        if metadata is not UNSET:
            field_dict["metadata"] = metadata
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.storage_attachment_metadata_type_0 import (
            StorageAttachmentMetadataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        parent_type = d.pop("parent_type")

        object_key = d.pop("object_key")

        storage_kind = d.pop("storage_kind")

        filename = d.pop("filename")

        content_type = d.pop("content_type")

        size_bytes = d.pop("size_bytes")

        content_hash = d.pop("content_hash")

        status = StorageAttachmentStatus(d.pop("status"))

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parent_id", UNSET))

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

        duration_ms = _parse_duration_ms(d.pop("duration_ms", UNSET))

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

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["file"] | Unset, d.pop("object", UNSET))
        if object_ != "file" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'file', got '{object_}'")

        get_v1_files_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            parent_type=parent_type,
            object_key=object_key,
            storage_kind=storage_kind,
            filename=filename,
            content_type=content_type,
            size_bytes=size_bytes,
            content_hash=content_hash,
            status=status,
            created=created,
            updated=updated,
            parent_id=parent_id,
            width=width,
            height=height,
            duration_ms=duration_ms,
            metadata=metadata,
            deleted_at=deleted_at,
            object_=object_,
        )

        get_v1_files_response_200_data_item.additional_properties = d
        return get_v1_files_response_200_data_item

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
