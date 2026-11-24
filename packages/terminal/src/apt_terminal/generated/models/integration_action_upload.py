from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionUpload")


@_attrs_define
class IntegrationActionUpload:
    """actionType=upload — google-photos: turn an upload token (from the uploads route) into a media item, optionally
    inside an album

        Attributes:
            upload_token (str):
            file_name (str):
            album_id (str | Unset):
            description (str | Unset):
    """

    upload_token: str
    file_name: str
    album_id: str | Unset = UNSET
    description: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        upload_token = self.upload_token

        file_name = self.file_name

        album_id = self.album_id

        description = self.description

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "upload_token": upload_token,
                "file_name": file_name,
            }
        )
        if album_id is not UNSET:
            field_dict["album_id"] = album_id
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        upload_token = d.pop("upload_token")

        file_name = d.pop("file_name")

        album_id = d.pop("album_id", UNSET)

        description = d.pop("description", UNSET)

        integration_action_upload = cls(
            upload_token=upload_token,
            file_name=file_name,
            album_id=album_id,
            description=description,
        )

        integration_action_upload.additional_properties = d
        return integration_action_upload

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
