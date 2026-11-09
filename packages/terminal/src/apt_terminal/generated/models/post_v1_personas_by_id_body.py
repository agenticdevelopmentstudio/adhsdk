from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_personas_by_id_body_canned_chat_type_0_type_1 import (
        PostV1PersonasByIdBodyCannedChatType0Type1,
    )
    from ..models.post_v1_personas_by_id_body_chat_status_type_0_type_1 import (
        PostV1PersonasByIdBodyChatStatusType0Type1,
    )


T = TypeVar("T", bound="PostV1PersonasByIdBody")


@_attrs_define
class PostV1PersonasByIdBody:
    """
    Attributes:
        slug (str | Unset):
        name (str | Unset):
        description (None | str | Unset):
        visibility (str | Unset):
        model (str | Unset):
        service_id (None | str | Unset):
        app_id (None | str | Unset):
        avatar_attachment_id (None | str | Unset):
        model_prompt (str | Unset):
        voice (None | str | Unset):
        character (None | str | Unset):
        examples (None | str | Unset):
        canned_chat (bool | float | list[Any] | None | PostV1PersonasByIdBodyCannedChatType0Type1 | str | Unset):
        chat_status (bool | float | list[Any] | None | PostV1PersonasByIdBodyChatStatusType0Type1 | str | Unset):
    """

    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    description: None | str | Unset = UNSET
    visibility: str | Unset = UNSET
    model: str | Unset = UNSET
    service_id: None | str | Unset = UNSET
    app_id: None | str | Unset = UNSET
    avatar_attachment_id: None | str | Unset = UNSET
    model_prompt: str | Unset = UNSET
    voice: None | str | Unset = UNSET
    character: None | str | Unset = UNSET
    examples: None | str | Unset = UNSET
    canned_chat: (
        bool | float | list[Any] | None | PostV1PersonasByIdBodyCannedChatType0Type1 | str | Unset
    ) = UNSET
    chat_status: (
        bool | float | list[Any] | None | PostV1PersonasByIdBodyChatStatusType0Type1 | str | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_personas_by_id_body_canned_chat_type_0_type_1 import (
            PostV1PersonasByIdBodyCannedChatType0Type1,
        )
        from ..models.post_v1_personas_by_id_body_chat_status_type_0_type_1 import (
            PostV1PersonasByIdBodyChatStatusType0Type1,
        )

        slug = self.slug

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        visibility = self.visibility

        model = self.model

        service_id: None | str | Unset
        if isinstance(self.service_id, Unset):
            service_id = UNSET
        else:
            service_id = self.service_id

        app_id: None | str | Unset
        if isinstance(self.app_id, Unset):
            app_id = UNSET
        else:
            app_id = self.app_id

        avatar_attachment_id: None | str | Unset
        if isinstance(self.avatar_attachment_id, Unset):
            avatar_attachment_id = UNSET
        else:
            avatar_attachment_id = self.avatar_attachment_id

        model_prompt = self.model_prompt

        voice: None | str | Unset
        if isinstance(self.voice, Unset):
            voice = UNSET
        else:
            voice = self.voice

        character: None | str | Unset
        if isinstance(self.character, Unset):
            character = UNSET
        else:
            character = self.character

        examples: None | str | Unset
        if isinstance(self.examples, Unset):
            examples = UNSET
        else:
            examples = self.examples

        canned_chat: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.canned_chat, Unset):
            canned_chat = UNSET
        elif isinstance(self.canned_chat, PostV1PersonasByIdBodyCannedChatType0Type1):
            canned_chat = self.canned_chat.to_dict()
        elif isinstance(self.canned_chat, list):
            canned_chat = self.canned_chat

        else:
            canned_chat = self.canned_chat

        chat_status: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.chat_status, Unset):
            chat_status = UNSET
        elif isinstance(self.chat_status, PostV1PersonasByIdBodyChatStatusType0Type1):
            chat_status = self.chat_status.to_dict()
        elif isinstance(self.chat_status, list):
            chat_status = self.chat_status

        else:
            chat_status = self.chat_status

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if model is not UNSET:
            field_dict["model"] = model
        if service_id is not UNSET:
            field_dict["service_id"] = service_id
        if app_id is not UNSET:
            field_dict["app_id"] = app_id
        if avatar_attachment_id is not UNSET:
            field_dict["avatar_attachment_id"] = avatar_attachment_id
        if model_prompt is not UNSET:
            field_dict["model_prompt"] = model_prompt
        if voice is not UNSET:
            field_dict["voice"] = voice
        if character is not UNSET:
            field_dict["character"] = character
        if examples is not UNSET:
            field_dict["examples"] = examples
        if canned_chat is not UNSET:
            field_dict["canned_chat"] = canned_chat
        if chat_status is not UNSET:
            field_dict["chat_status"] = chat_status

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_personas_by_id_body_canned_chat_type_0_type_1 import (
            PostV1PersonasByIdBodyCannedChatType0Type1,
        )
        from ..models.post_v1_personas_by_id_body_chat_status_type_0_type_1 import (
            PostV1PersonasByIdBodyChatStatusType0Type1,
        )

        d = dict(src_dict)
        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        visibility = d.pop("visibility", UNSET)

        model = d.pop("model", UNSET)

        def _parse_service_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        service_id = _parse_service_id(d.pop("service_id", UNSET))

        def _parse_app_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        app_id = _parse_app_id(d.pop("app_id", UNSET))

        def _parse_avatar_attachment_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        avatar_attachment_id = _parse_avatar_attachment_id(d.pop("avatar_attachment_id", UNSET))

        model_prompt = d.pop("model_prompt", UNSET)

        def _parse_voice(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        voice = _parse_voice(d.pop("voice", UNSET))

        def _parse_character(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        character = _parse_character(d.pop("character", UNSET))

        def _parse_examples(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        examples = _parse_examples(d.pop("examples", UNSET))

        def _parse_canned_chat(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1PersonasByIdBodyCannedChatType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                canned_chat_type_0_type_1 = PostV1PersonasByIdBodyCannedChatType0Type1.from_dict(
                    data
                )

                return canned_chat_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                canned_chat_type_0_type_2 = cast(list[Any], data)

                return canned_chat_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1PersonasByIdBodyCannedChatType0Type1
                | str
                | Unset,
                data,
            )

        canned_chat = _parse_canned_chat(d.pop("canned_chat", UNSET))

        def _parse_chat_status(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1PersonasByIdBodyChatStatusType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                chat_status_type_0_type_1 = PostV1PersonasByIdBodyChatStatusType0Type1.from_dict(
                    data
                )

                return chat_status_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                chat_status_type_0_type_2 = cast(list[Any], data)

                return chat_status_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1PersonasByIdBodyChatStatusType0Type1
                | str
                | Unset,
                data,
            )

        chat_status = _parse_chat_status(d.pop("chat_status", UNSET))

        post_v1_personas_by_id_body = cls(
            slug=slug,
            name=name,
            description=description,
            visibility=visibility,
            model=model,
            service_id=service_id,
            app_id=app_id,
            avatar_attachment_id=avatar_attachment_id,
            model_prompt=model_prompt,
            voice=voice,
            character=character,
            examples=examples,
            canned_chat=canned_chat,
            chat_status=chat_status,
        )

        return post_v1_personas_by_id_body
