from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_action_media_item import IntegrationActionMediaItem


T = TypeVar("T", bound="IntegrationActionComment")


@_attrs_define
class IntegrationActionComment:
    """actionType=comment — a Reddit reply (reuses the post shape); requires non-empty text and replyTo (a t1_/t3_
    fullname); media is rejected by the handler

        Attributes:
            text (str | Unset):
            media (list[IntegrationActionMediaItem] | Unset):
            reply_to (str | Unset): The t1_/t3_ fullname being replied to
    """

    text: str | Unset = UNSET
    media: list[IntegrationActionMediaItem] | Unset = UNSET
    reply_to: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        text = self.text

        media: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.media, Unset):
            media = []
            for media_item_data in self.media:
                media_item = media_item_data.to_dict()
                media.append(media_item)

        reply_to = self.reply_to

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if text is not UNSET:
            field_dict["text"] = text
        if media is not UNSET:
            field_dict["media"] = media
        if reply_to is not UNSET:
            field_dict["reply_to"] = reply_to

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_action_media_item import (
            IntegrationActionMediaItem,
        )

        d = dict(src_dict)
        text = d.pop("text", UNSET)

        _media = d.pop("media", UNSET)
        media: list[IntegrationActionMediaItem] | Unset = UNSET
        if _media is not UNSET:
            media = []
            for media_item_data in _media:
                media_item = IntegrationActionMediaItem.from_dict(media_item_data)

                media.append(media_item)

        reply_to = d.pop("reply_to", UNSET)

        integration_action_comment = cls(
            text=text,
            media=media,
            reply_to=reply_to,
        )

        integration_action_comment.additional_properties = d
        return integration_action_comment

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
