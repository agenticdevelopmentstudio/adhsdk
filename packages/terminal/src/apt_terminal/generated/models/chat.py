from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.chat_type import ChatType

if TYPE_CHECKING:
    from ..models.chat_participant import ChatParticipant


T = TypeVar("T", bound="Chat")


@_attrs_define
class Chat:
    """
    Attributes:
        id (str):
        type_ (ChatType):
        definition_id (str): The definition the chat follows; a DM reports the built-in `direct`’s id
        name (str):
        photo_storage_key (None | str):
        created_by_user_id (None | str):
        created_at (str):
        updated_at (str):
        participants (list[ChatParticipant]): Joined participants, longest-standing first
    """

    id: str
    type_: ChatType
    definition_id: str
    name: str
    photo_storage_key: None | str
    created_by_user_id: None | str
    created_at: str
    updated_at: str
    participants: list[ChatParticipant]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        type_ = self.type_.value

        definition_id = self.definition_id

        name = self.name

        photo_storage_key: None | str
        photo_storage_key = self.photo_storage_key

        created_by_user_id: None | str
        created_by_user_id = self.created_by_user_id

        created_at = self.created_at

        updated_at = self.updated_at

        participants = []
        for participants_item_data in self.participants:
            participants_item = participants_item_data.to_dict()
            participants.append(participants_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "type": type_,
                "definitionId": definition_id,
                "name": name,
                "photoStorageKey": photo_storage_key,
                "createdByUserId": created_by_user_id,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "participants": participants,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat_participant import ChatParticipant

        d = dict(src_dict)
        id = d.pop("id")

        type_ = ChatType(d.pop("type"))

        definition_id = d.pop("definitionId")

        name = d.pop("name")

        def _parse_photo_storage_key(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        photo_storage_key = _parse_photo_storage_key(d.pop("photoStorageKey"))

        def _parse_created_by_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by_user_id = _parse_created_by_user_id(d.pop("createdByUserId"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        participants = []
        _participants = d.pop("participants")
        for participants_item_data in _participants:
            participants_item = ChatParticipant.from_dict(participants_item_data)

            participants.append(participants_item)

        chat = cls(
            id=id,
            type_=type_,
            definition_id=definition_id,
            name=name,
            photo_storage_key=photo_storage_key,
            created_by_user_id=created_by_user_id,
            created_at=created_at,
            updated_at=updated_at,
            participants=participants,
        )

        chat.additional_properties = d
        return chat

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
