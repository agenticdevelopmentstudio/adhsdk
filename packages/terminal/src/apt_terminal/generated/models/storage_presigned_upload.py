from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.storage_attachment import StorageAttachment


T = TypeVar("T", bound="StoragePresignedUpload")


@_attrs_define
class StoragePresignedUpload:
    """
    Attributes:
        attachment (StorageAttachment):
        upload_url (str): Presigned PUT URL — upload the bytes directly to R2.
    """

    attachment: StorageAttachment
    upload_url: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        attachment = self.attachment.to_dict()

        upload_url = self.upload_url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "attachment": attachment,
                "upload_url": upload_url,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.storage_attachment import StorageAttachment

        d = dict(src_dict)
        attachment = StorageAttachment.from_dict(d.pop("attachment"))

        upload_url = d.pop("upload_url")

        storage_presigned_upload = cls(
            attachment=attachment,
            upload_url=upload_url,
        )

        storage_presigned_upload.additional_properties = d
        return storage_presigned_upload

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
