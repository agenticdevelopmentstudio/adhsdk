from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.visitor_conversation_state import VisitorConversationState

T = TypeVar("T", bound="VisitorConversation")


@_attrs_define
class VisitorConversation:
    """
    Attributes:
        id (str):
        title (str):
        model (str): The persona's configured model, copied at creation
        persona_slug (None | str):
        persona_id (None | str):
        state (VisitorConversationState):
        created_at (str):
        updated_at (str):
    """

    id: str
    title: str
    model: str
    persona_slug: None | str
    persona_id: None | str
    state: VisitorConversationState
    created_at: str
    updated_at: str
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

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "title": title,
                "model": model,
                "personaSlug": persona_slug,
                "personaId": persona_id,
                "state": state,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

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

        persona_slug = _parse_persona_slug(d.pop("personaSlug"))

        def _parse_persona_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        persona_id = _parse_persona_id(d.pop("personaId"))

        state = VisitorConversationState(d.pop("state"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        visitor_conversation = cls(
            id=id,
            title=title,
            model=model,
            persona_slug=persona_slug,
            persona_id=persona_id,
            state=state,
            created_at=created_at,
            updated_at=updated_at,
        )

        visitor_conversation.additional_properties = d
        return visitor_conversation

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
