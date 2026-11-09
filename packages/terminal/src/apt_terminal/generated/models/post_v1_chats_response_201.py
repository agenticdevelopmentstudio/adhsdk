from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.chat import Chat


T = TypeVar("T", bound="PostV1ChatsResponse201")


@_attrs_define
class PostV1ChatsResponse201:
    """
    Attributes:
        chat (Chat):
        skipped_persona_ids (list[str]): The definition’s own personas that were not seated because they no longer exist
        object_ (Literal['chat'] | Unset):
    """

    chat: Chat
    skipped_persona_ids: list[str]
    object_: Literal["chat"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chat = self.chat.to_dict()

        skipped_persona_ids = self.skipped_persona_ids

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chat": chat,
                "skipped_persona_ids": skipped_persona_ids,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat import Chat

        d = dict(src_dict)
        chat = Chat.from_dict(d.pop("chat"))

        skipped_persona_ids = cast(list[str], d.pop("skipped_persona_ids"))

        object_ = cast(Literal["chat"] | Unset, d.pop("object", UNSET))
        if object_ != "chat" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'chat', got '{object_}'")

        post_v1_chats_response_201 = cls(
            chat=chat,
            skipped_persona_ids=skipped_persona_ids,
            object_=object_,
        )

        post_v1_chats_response_201.additional_properties = d
        return post_v1_chats_response_201

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
