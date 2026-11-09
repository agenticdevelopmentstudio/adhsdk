from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.visitor_conversation_state import VisitorConversationState
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1VisitorChatsResponse201")


@_attrs_define
class PostV1VisitorChatsResponse201:
    """
    Attributes:
        id (str):
        title (str):
        model (str): The persona's configured model, copied at creation
        persona_slug (None | str):
        persona_id (None | str):
        state (VisitorConversationState):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['visitor_chat'] | Unset):
    """

    id: str
    title: str
    model: str
    persona_slug: None | str
    persona_id: None | str
    state: VisitorConversationState
    created: int
    updated: int
    object_: Literal["visitor_chat"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        title = self.title

        model = self.model

        persona_slug: None | str
        persona_slug = self.persona_slug

        persona_id: None | str
        persona_id = self.persona_id

        state = self.state.value

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "title": title,
                "model": model,
                "persona_slug": persona_slug,
                "persona_id": persona_id,
                "state": state,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        title = d.pop("title")

        model = d.pop("model")

        def _parse_persona_slug(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        persona_slug = _parse_persona_slug(d.pop("persona_slug"))

        def _parse_persona_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        persona_id = _parse_persona_id(d.pop("persona_id"))

        state = VisitorConversationState(d.pop("state"))

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["visitor_chat"] | Unset, d.pop("object", UNSET))
        if object_ != "visitor_chat" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'visitor_chat', got '{object_}'")

        post_v1_visitor_chats_response_201 = cls(
            id=id,
            title=title,
            model=model,
            persona_slug=persona_slug,
            persona_id=persona_id,
            state=state,
            created=created,
            updated=updated,
            object_=object_,
        )

        post_v1_visitor_chats_response_201.additional_properties = d
        return post_v1_visitor_chats_response_201

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
