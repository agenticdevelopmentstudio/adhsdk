from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1FilesBody")


@_attrs_define
class PostV1FilesBody:
    """
    Attributes:
        filename (str):
        content_type (str):
        parent_type (str | Unset): Kind of row the attachment hangs off, e.g. 'persona' or 'registry.entry' (defaults to
            'standalone').
        parent_id (str | Unset): Id of the row the attachment hangs off.
        owner_type (str | Unset): Legacy name for parentType; read only when parentType is absent.
        owner_id (str | Unset): Legacy name for parentId; read only when parentId is absent.
        ecosystem_id (None | str | Unset):
        size_bytes (int | Unset): Declared size; enforced against the storage quota at init.
        content_hash (str | Unset): When it matches an existing ready object, the upload is deduplicated.
    """

    filename: str
    content_type: str
    parent_type: str | Unset = UNSET
    parent_id: str | Unset = UNSET
    owner_type: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    ecosystem_id: None | str | Unset = UNSET
    size_bytes: int | Unset = UNSET
    content_hash: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        filename = self.filename

        content_type = self.content_type

        parent_type = self.parent_type

        parent_id = self.parent_id

        owner_type = self.owner_type

        owner_id = self.owner_id

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = self.ecosystem_id

        size_bytes = self.size_bytes

        content_hash = self.content_hash

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "filename": filename,
                "content_type": content_type,
            }
        )
        if parent_type is not UNSET:
            field_dict["parent_type"] = parent_type
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if owner_type is not UNSET:
            field_dict["owner_type"] = owner_type
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if size_bytes is not UNSET:
            field_dict["size_bytes"] = size_bytes
        if content_hash is not UNSET:
            field_dict["content_hash"] = content_hash

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        filename = d.pop("filename")

        content_type = d.pop("content_type")

        parent_type = d.pop("parent_type", UNSET)

        parent_id = d.pop("parent_id", UNSET)

        owner_type = d.pop("owner_type", UNSET)

        owner_id = d.pop("owner_id", UNSET)

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystem_id", UNSET))

        size_bytes = d.pop("size_bytes", UNSET)

        content_hash = d.pop("content_hash", UNSET)

        post_v1_files_body = cls(
            filename=filename,
            content_type=content_type,
            parent_type=parent_type,
            parent_id=parent_id,
            owner_type=owner_type,
            owner_id=owner_id,
            ecosystem_id=ecosystem_id,
            size_bytes=size_bytes,
            content_hash=content_hash,
        )

        post_v1_files_body.additional_properties = d
        return post_v1_files_body

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
