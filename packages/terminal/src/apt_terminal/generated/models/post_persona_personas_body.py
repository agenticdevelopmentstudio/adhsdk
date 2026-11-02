from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_persona_personas_body_canned_chat_type_0_type_1 import (
        PostPersonaPersonasBodyCannedChatType0Type1,
    )
    from ..models.post_persona_personas_body_chat_status_type_0_type_1 import (
        PostPersonaPersonasBodyChatStatusType0Type1,
    )


T = TypeVar("T", bound="PostPersonaPersonasBody")


@_attrs_define
class PostPersonaPersonasBody:
    """
    Attributes:
        slug (str):
        name (str):
        model (str):
        model_prompt (str):
        description (None | str | Unset):
        visibility (str | Unset):
        service_id (None | str | Unset):
        app_id (None | str | Unset):
        avatar_attachment_id (None | str | Unset):
        voice (None | str | Unset):
        character (None | str | Unset):
        examples (None | str | Unset):
        canned_chat (bool | float | list[Any] | None | PostPersonaPersonasBodyCannedChatType0Type1 | str | Unset):
        chat_status (bool | float | list[Any] | None | PostPersonaPersonasBodyChatStatusType0Type1 | str | Unset):
        id (str | Unset):
    """

    slug: str
    name: str
    model: str
    model_prompt: str
    description: None | str | Unset = UNSET
    visibility: str | Unset = UNSET
    service_id: None | str | Unset = UNSET
    app_id: None | str | Unset = UNSET
    avatar_attachment_id: None | str | Unset = UNSET
    voice: None | str | Unset = UNSET
    character: None | str | Unset = UNSET
    examples: None | str | Unset = UNSET
    canned_chat: (
        bool | float | list[Any] | None | PostPersonaPersonasBodyCannedChatType0Type1 | str | Unset
    ) = UNSET
    chat_status: (
        bool | float | list[Any] | None | PostPersonaPersonasBodyChatStatusType0Type1 | str | Unset
    ) = UNSET
    id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_persona_personas_body_canned_chat_type_0_type_1 import (
            PostPersonaPersonasBodyCannedChatType0Type1,
        )
        from ..models.post_persona_personas_body_chat_status_type_0_type_1 import (
            PostPersonaPersonasBodyChatStatusType0Type1,
        )

        slug = self.slug

        name = self.name

        model = self.model

        model_prompt = self.model_prompt

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        visibility = self.visibility

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
        elif isinstance(self.canned_chat, PostPersonaPersonasBodyCannedChatType0Type1):
            canned_chat = self.canned_chat.to_dict()
        elif isinstance(self.canned_chat, list):
            canned_chat = self.canned_chat

        else:
            canned_chat = self.canned_chat

        chat_status: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.chat_status, Unset):
            chat_status = UNSET
        elif isinstance(self.chat_status, PostPersonaPersonasBodyChatStatusType0Type1):
            chat_status = self.chat_status.to_dict()
        elif isinstance(self.chat_status, list):
            chat_status = self.chat_status

        else:
            chat_status = self.chat_status

        id = self.id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "model": model,
                "modelPrompt": model_prompt,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if service_id is not UNSET:
            field_dict["serviceId"] = service_id
        if app_id is not UNSET:
            field_dict["appId"] = app_id
        if avatar_attachment_id is not UNSET:
            field_dict["avatarAttachmentId"] = avatar_attachment_id
        if voice is not UNSET:
            field_dict["voice"] = voice
        if character is not UNSET:
            field_dict["character"] = character
        if examples is not UNSET:
            field_dict["examples"] = examples
        if canned_chat is not UNSET:
            field_dict["cannedChat"] = canned_chat
        if chat_status is not UNSET:
            field_dict["chatStatus"] = chat_status
        if id is not UNSET:
            field_dict["id"] = id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_persona_personas_body_canned_chat_type_0_type_1 import (
            PostPersonaPersonasBodyCannedChatType0Type1,
        )
        from ..models.post_persona_personas_body_chat_status_type_0_type_1 import (
            PostPersonaPersonasBodyChatStatusType0Type1,
        )

        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        model = d.pop("model")

        model_prompt = d.pop("modelPrompt")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        visibility = d.pop("visibility", UNSET)

        def _parse_service_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        service_id = _parse_service_id(d.pop("serviceId", UNSET))

        def _parse_app_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        app_id = _parse_app_id(d.pop("appId", UNSET))

        def _parse_avatar_attachment_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        avatar_attachment_id = _parse_avatar_attachment_id(d.pop("avatarAttachmentId", UNSET))

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
            | PostPersonaPersonasBodyCannedChatType0Type1
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
                canned_chat_type_0_type_1 = PostPersonaPersonasBodyCannedChatType0Type1.from_dict(
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
                | PostPersonaPersonasBodyCannedChatType0Type1
                | str
                | Unset,
                data,
            )

        canned_chat = _parse_canned_chat(d.pop("cannedChat", UNSET))

        def _parse_chat_status(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostPersonaPersonasBodyChatStatusType0Type1
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
                chat_status_type_0_type_1 = PostPersonaPersonasBodyChatStatusType0Type1.from_dict(
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
                | PostPersonaPersonasBodyChatStatusType0Type1
                | str
                | Unset,
                data,
            )

        chat_status = _parse_chat_status(d.pop("chatStatus", UNSET))

        id = d.pop("id", UNSET)

        post_persona_personas_body = cls(
            slug=slug,
            name=name,
            model=model,
            model_prompt=model_prompt,
            description=description,
            visibility=visibility,
            service_id=service_id,
            app_id=app_id,
            avatar_attachment_id=avatar_attachment_id,
            voice=voice,
            character=character,
            examples=examples,
            canned_chat=canned_chat,
            chat_status=chat_status,
            id=id,
        )

        return post_persona_personas_body
