from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostStorageUploadsBody")


@_attrs_define
class PostStorageUploadsBody:
    """
    Attributes:
        filename (str):
        content_type (str):
        owner_type (str | Unset): Polymorphic owner kind (defaults to 'standalone').
        ecosystem_id (None | str | Unset):
        size_bytes (int | Unset): Declared size; enforced against the storage quota at init.
        content_hash (str | Unset): When it matches an existing ready object, the upload is deduplicated.
    """

    filename: str
    content_type: str
    owner_type: str | Unset = UNSET
    ecosystem_id: None | str | Unset = UNSET
    size_bytes: int | Unset = UNSET
    content_hash: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        filename = self.filename

        content_type = self.content_type

        owner_type = self.owner_type

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
                "contentType": content_type,
            }
        )
        if owner_type is not UNSET:
            field_dict["ownerType"] = owner_type
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if size_bytes is not UNSET:
            field_dict["sizeBytes"] = size_bytes
        if content_hash is not UNSET:
            field_dict["contentHash"] = content_hash

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        filename = d.pop("filename")

        content_type = d.pop("contentType")

        owner_type = d.pop("ownerType", UNSET)

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId", UNSET))

        size_bytes = d.pop("sizeBytes", UNSET)

        content_hash = d.pop("contentHash", UNSET)

        post_storage_uploads_body = cls(
            filename=filename,
            content_type=content_type,
            owner_type=owner_type,
            ecosystem_id=ecosystem_id,
            size_bytes=size_bytes,
            content_hash=content_hash,
        )

        post_storage_uploads_body.additional_properties = d
        return post_storage_uploads_body

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
