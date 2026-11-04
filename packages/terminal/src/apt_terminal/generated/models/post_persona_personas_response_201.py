from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_persona_personas_response_201_canned_chat_type_0_type_1 import (
        PostPersonaPersonasResponse201CannedChatType0Type1,
    )
    from ..models.post_persona_personas_response_201_chat_status_type_0_type_1 import (
        PostPersonaPersonasResponse201ChatStatusType0Type1,
    )


T = TypeVar("T", bound="PostPersonaPersonasResponse201")


@_attrs_define
class PostPersonaPersonasResponse201:
    """
    Attributes:
        id (str):
        user_id (None | str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        slug (str):
        name (str):
        description (None | str):
        visibility (str):
        model (str):
        service_id (None | str):
        app_id (None | str):
        avatar_attachment_id (None | str):
        model_prompt (str):
        voice (None | str):
        character (None | str):
        examples (None | str):
        canned_chat (bool | float | list[Any] | None | PostPersonaPersonasResponse201CannedChatType0Type1 | str):
        chat_status (bool | float | list[Any] | None | PostPersonaPersonasResponse201ChatStatusType0Type1 | str):
        created_at (str):
        updated_at (str):
        owned_ecosystem_id (None | str | Unset):
        corpus_ecosystem_id (None | str | Unset):
    """

    id: str
    user_id: None | str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    slug: str
    name: str
    description: None | str
    visibility: str
    model: str
    service_id: None | str
    app_id: None | str
    avatar_attachment_id: None | str
    model_prompt: str
    voice: None | str
    character: None | str
    examples: None | str
    canned_chat: (
        bool | float | list[Any] | None | PostPersonaPersonasResponse201CannedChatType0Type1 | str
    )
    chat_status: (
        bool | float | list[Any] | None | PostPersonaPersonasResponse201ChatStatusType0Type1 | str
    )
    created_at: str
    updated_at: str
    owned_ecosystem_id: None | str | Unset = UNSET
    corpus_ecosystem_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_persona_personas_response_201_canned_chat_type_0_type_1 import (
            PostPersonaPersonasResponse201CannedChatType0Type1,
        )
        from ..models.post_persona_personas_response_201_chat_status_type_0_type_1 import (
            PostPersonaPersonasResponse201ChatStatusType0Type1,
        )

        id = self.id

        user_id: None | str
        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        slug = self.slug

        name = self.name

        description: None | str
        description = self.description

        visibility = self.visibility

        model = self.model

        service_id: None | str
        service_id = self.service_id

        app_id: None | str
        app_id = self.app_id

        avatar_attachment_id: None | str
        avatar_attachment_id = self.avatar_attachment_id

        model_prompt = self.model_prompt

        voice: None | str
        voice = self.voice

        character: None | str
        character = self.character

        examples: None | str
        examples = self.examples

        canned_chat: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.canned_chat, PostPersonaPersonasResponse201CannedChatType0Type1):
            canned_chat = self.canned_chat.to_dict()
        elif isinstance(self.canned_chat, list):
            canned_chat = self.canned_chat

        else:
            canned_chat = self.canned_chat

        chat_status: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.chat_status, PostPersonaPersonasResponse201ChatStatusType0Type1):
            chat_status = self.chat_status.to_dict()
        elif isinstance(self.chat_status, list):
            chat_status = self.chat_status

        else:
            chat_status = self.chat_status

        created_at = self.created_at

        updated_at = self.updated_at

        owned_ecosystem_id: None | str | Unset
        if isinstance(self.owned_ecosystem_id, Unset):
            owned_ecosystem_id = UNSET
        else:
            owned_ecosystem_id = self.owned_ecosystem_id

        corpus_ecosystem_id: None | str | Unset
        if isinstance(self.corpus_ecosystem_id, Unset):
            corpus_ecosystem_id = UNSET
        else:
            corpus_ecosystem_id = self.corpus_ecosystem_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "userId": user_id,
                "authorKind": author_kind,
                "authorId": author_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "slug": slug,
                "name": name,
                "description": description,
                "visibility": visibility,
                "model": model,
                "serviceId": service_id,
                "appId": app_id,
                "avatarAttachmentId": avatar_attachment_id,
                "modelPrompt": model_prompt,
                "voice": voice,
                "character": character,
                "examples": examples,
                "cannedChat": canned_chat,
                "chatStatus": chat_status,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if owned_ecosystem_id is not UNSET:
            field_dict["ownedEcosystemId"] = owned_ecosystem_id
        if corpus_ecosystem_id is not UNSET:
            field_dict["corpusEcosystemId"] = corpus_ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_persona_personas_response_201_canned_chat_type_0_type_1 import (
            PostPersonaPersonasResponse201CannedChatType0Type1,
        )
        from ..models.post_persona_personas_response_201_chat_status_type_0_type_1 import (
            PostPersonaPersonasResponse201ChatStatusType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        def _parse_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        user_id = _parse_user_id(d.pop("userId"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        visibility = d.pop("visibility")

        model = d.pop("model")

        def _parse_service_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        service_id = _parse_service_id(d.pop("serviceId"))

        def _parse_app_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        app_id = _parse_app_id(d.pop("appId"))

        def _parse_avatar_attachment_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        avatar_attachment_id = _parse_avatar_attachment_id(d.pop("avatarAttachmentId"))

        model_prompt = d.pop("modelPrompt")

        def _parse_voice(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        voice = _parse_voice(d.pop("voice"))

        def _parse_character(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        character = _parse_character(d.pop("character"))

        def _parse_examples(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        examples = _parse_examples(d.pop("examples"))

        def _parse_canned_chat(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostPersonaPersonasResponse201CannedChatType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                canned_chat_type_0_type_1 = (
                    PostPersonaPersonasResponse201CannedChatType0Type1.from_dict(data)
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
                | PostPersonaPersonasResponse201CannedChatType0Type1
                | str,
                data,
            )

        canned_chat = _parse_canned_chat(d.pop("cannedChat"))

        def _parse_chat_status(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostPersonaPersonasResponse201ChatStatusType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                chat_status_type_0_type_1 = (
                    PostPersonaPersonasResponse201ChatStatusType0Type1.from_dict(data)
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
                | PostPersonaPersonasResponse201ChatStatusType0Type1
                | str,
                data,
            )

        chat_status = _parse_chat_status(d.pop("chatStatus"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_owned_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        owned_ecosystem_id = _parse_owned_ecosystem_id(d.pop("ownedEcosystemId", UNSET))

        def _parse_corpus_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        corpus_ecosystem_id = _parse_corpus_ecosystem_id(d.pop("corpusEcosystemId", UNSET))

        post_persona_personas_response_201 = cls(
            id=id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
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
            created_at=created_at,
            updated_at=updated_at,
            owned_ecosystem_id=owned_ecosystem_id,
            corpus_ecosystem_id=corpus_ecosystem_id,
        )

        return post_persona_personas_response_201
