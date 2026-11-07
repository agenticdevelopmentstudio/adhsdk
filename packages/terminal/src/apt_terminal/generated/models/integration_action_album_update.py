from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionAlbumUpdate")


@_attrs_define
class IntegrationActionAlbumUpdate:
    """actionType=album_update — google-photos: rename and/or set the cover of an app-created album; title or
    coverPhotoMediaItemId is required

        Attributes:
            album_id (str):
            title (str | Unset):
            cover_photo_media_item_id (str | Unset):
    """

    album_id: str
    title: str | Unset = UNSET
    cover_photo_media_item_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        album_id = self.album_id

        title = self.title

        cover_photo_media_item_id = self.cover_photo_media_item_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "albumId": album_id,
            }
        )
        if title is not UNSET:
            field_dict["title"] = title
        if cover_photo_media_item_id is not UNSET:
            field_dict["coverPhotoMediaItemId"] = cover_photo_media_item_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        album_id = d.pop("albumId")

        title = d.pop("title", UNSET)

        cover_photo_media_item_id = d.pop("coverPhotoMediaItemId", UNSET)

        integration_action_album_update = cls(
            album_id=album_id,
            title=title,
            cover_photo_media_item_id=cover_photo_media_item_id,
        )

        integration_action_album_update.additional_properties = d
        return integration_action_album_update

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
