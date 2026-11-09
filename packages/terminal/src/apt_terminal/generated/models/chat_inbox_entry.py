from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.chat_type import ChatType

if TYPE_CHECKING:
    from ..models.chat_participant import ChatParticipant
    from ..models.dm_message_preview_type_0 import DmMessagePreviewType0


T = TypeVar("T", bound="ChatInboxEntry")


@_attrs_define
class ChatInboxEntry:
    """One row of the caller’s chat list: a chat, its last message and unread count.

    Attributes:
        id (str):
        type_ (ChatType):
        definition_id (str): The definition the chat follows; a DM reports the built-in `direct`’s id
        name (str):
        photo_storage_key (None | str):
        created_by_user_id (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        participants (list[ChatParticipant]): Joined participants, longest-standing first
        last_message (DmMessagePreviewType0 | None): The chat's most recent message, trimmed to what a chat list
            renders.
        unread_count (int):
    """

    id: str
    type_: ChatType
    definition_id: str
    name: str
    photo_storage_key: None | str
    created_by_user_id: None | str
    created: int
    updated: int
    participants: list[ChatParticipant]
    last_message: DmMessagePreviewType0 | None
    unread_count: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.dm_message_preview_type_0 import DmMessagePreviewType0

        id = self.id

        type_ = self.type_.value

        definition_id = self.definition_id

        name = self.name

        photo_storage_key: None | str
        photo_storage_key = self.photo_storage_key

        created_by_user_id: None | str
        created_by_user_id = self.created_by_user_id

        created = self.created

        updated = self.updated

        participants = []
        for participants_item_data in self.participants:
            participants_item = participants_item_data.to_dict()
            participants.append(participants_item)

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
                "id": id,
                "type": type_,
                "definition_id": definition_id,
                "name": name,
                "photo_storage_key": photo_storage_key,
                "created_by_user_id": created_by_user_id,
                "created": created,
                "updated": updated,
                "participants": participants,
                "last_message": last_message,
                "unread_count": unread_count,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat_participant import ChatParticipant
        from ..models.dm_message_preview_type_0 import DmMessagePreviewType0

        d = dict(src_dict)
        id = d.pop("id")

        type_ = ChatType(d.pop("type"))

        definition_id = d.pop("definition_id")

        name = d.pop("name")

        def _parse_photo_storage_key(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        photo_storage_key = _parse_photo_storage_key(d.pop("photo_storage_key"))

        def _parse_created_by_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by_user_id = _parse_created_by_user_id(d.pop("created_by_user_id"))

        created = d.pop("created")

        updated = d.pop("updated")

        participants = []
        _participants = d.pop("participants")
        for participants_item_data in _participants:
            participants_item = ChatParticipant.from_dict(participants_item_data)

            participants.append(participants_item)

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

        chat_inbox_entry = cls(
            id=id,
            type_=type_,
            definition_id=definition_id,
            name=name,
            photo_storage_key=photo_storage_key,
            created_by_user_id=created_by_user_id,
            created=created,
            updated=updated,
            participants=participants,
            last_message=last_message,
            unread_count=unread_count,
        )

        chat_inbox_entry.additional_properties = d
        return chat_inbox_entry

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
