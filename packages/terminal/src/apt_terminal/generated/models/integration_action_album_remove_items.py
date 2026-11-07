from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationActionAlbumRemoveItems")


@_attrs_define
class IntegrationActionAlbumRemoveItems:
    """actionType=album_remove_items — google-photos: take app-created items out of an app-created album (1 to 50 ids)

    Attributes:
        album_id (str):
        media_item_ids (list[str]):
    """

    album_id: str
    media_item_ids: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        album_id = self.album_id

        media_item_ids = self.media_item_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "albumId": album_id,
                "mediaItemIds": media_item_ids,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        album_id = d.pop("albumId")

        media_item_ids = cast(list[str], d.pop("mediaItemIds"))

        integration_action_album_remove_items = cls(
            album_id=album_id,
            media_item_ids=media_item_ids,
        )

        integration_action_album_remove_items.additional_properties = d
        return integration_action_album_remove_items

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
