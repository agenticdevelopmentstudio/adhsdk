from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="ChatConversation")


@_attrs_define
class ChatConversation:
    """
    Attributes:
        id (UUID):
        title (str):
        model (str):
        persona_slug (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: UUID
    title: str
    model: str
    persona_slug: None | str
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        title = self.title

        model = self.model

        persona_slug: None | str
        persona_slug = self.persona_slug

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "title": title,
                "model": model,
                "persona_slug": persona_slug,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        title = d.pop("title")

        model = d.pop("model")

        def _parse_persona_slug(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        persona_slug = _parse_persona_slug(d.pop("persona_slug"))

        created = d.pop("created")

        updated = d.pop("updated")

        chat_conversation = cls(
            id=id,
            title=title,
            model=model,
            persona_slug=persona_slug,
            created=created,
            updated=updated,
        )

        chat_conversation.additional_properties = d
        return chat_conversation

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
