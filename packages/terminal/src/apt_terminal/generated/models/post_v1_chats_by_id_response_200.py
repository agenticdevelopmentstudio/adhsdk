from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.chat_type import ChatType
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.chat_participant import ChatParticipant


T = TypeVar("T", bound="PostV1ChatsByIdResponse200")


@_attrs_define
class PostV1ChatsByIdResponse200:
    """
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
        object_ (Literal['chat'] | Unset):
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
    object_: Literal["chat"] | Unset = UNSET
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

        created = self.created

        updated = self.updated

        participants = []
        for participants_item_data in self.participants:
            participants_item = participants_item_data.to_dict()
            participants.append(participants_item)

        object_ = self.object_

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
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat_participant import ChatParticipant

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

        object_ = cast(Literal["chat"] | Unset, d.pop("object", UNSET))
        if object_ != "chat" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'chat', got '{object_}'")

        post_v1_chats_by_id_response_200 = cls(
            id=id,
            type_=type_,
            definition_id=definition_id,
            name=name,
            photo_storage_key=photo_storage_key,
            created_by_user_id=created_by_user_id,
            created=created,
            updated=updated,
            participants=participants,
            object_=object_,
        )

        post_v1_chats_by_id_response_200.additional_properties = d
        return post_v1_chats_by_id_response_200

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
