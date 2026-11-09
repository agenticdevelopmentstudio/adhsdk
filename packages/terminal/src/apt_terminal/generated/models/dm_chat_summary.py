from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.dm_message_preview_type_0 import DmMessagePreviewType0


T = TypeVar("T", bound="DmChatSummary")


@_attrs_define
class DmChatSummary:
    """
    Attributes:
        chat_id (str):
        other_user_id (str):
        last_message (DmMessagePreviewType0 | None): The chat's most recent message, trimmed to what a chat list
            renders.
        unread_count (int):
    """

    chat_id: str
    other_user_id: str
    last_message: DmMessagePreviewType0 | None
    unread_count: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.dm_message_preview_type_0 import DmMessagePreviewType0

        chat_id = self.chat_id

        other_user_id = self.other_user_id

        last_message: dict[str, Any] | None
        if isinstance(self.last_message, DmMessagePreviewType0):
            last_message = self.last_message.to_dict()
        else:
            last_message = self.last_message

        unread_count = self.unread_count

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chat_id": chat_id,
                "other_user_id": other_user_id,
                "last_message": last_message,
                "unread_count": unread_count,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.dm_message_preview_type_0 import DmMessagePreviewType0

        d = dict(src_dict)
        chat_id = d.pop("chat_id")

        other_user_id = d.pop("other_user_id")

        def _parse_last_message(data: object) -> DmMessagePreviewType0 | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_dm_message_preview_type_0 = DmMessagePreviewType0.from_dict(data)

                return componentsschemas_dm_message_preview_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(DmMessagePreviewType0 | None, data)

        last_message = _parse_last_message(d.pop("last_message"))

        unread_count = d.pop("unread_count")

        dm_chat_summary = cls(
            chat_id=chat_id,
            other_user_id=other_user_id,
            last_message=last_message,
            unread_count=unread_count,
        )

        dm_chat_summary.additional_properties = d
        return dm_chat_summary

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
