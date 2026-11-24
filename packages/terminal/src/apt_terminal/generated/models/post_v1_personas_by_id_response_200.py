from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_personas_by_id_response_200_canned_chat_type_0_type_1 import (
        PostV1PersonasByIdResponse200CannedChatType0Type1,
    )
    from ..models.post_v1_personas_by_id_response_200_chat_status_type_0_type_1 import (
        PostV1PersonasByIdResponse200ChatStatusType0Type1,
    )


T = TypeVar("T", bound="PostV1PersonasByIdResponse200")


@_attrs_define
class PostV1PersonasByIdResponse200:
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
        canned_chat (bool | float | list[Any] | None | PostV1PersonasByIdResponse200CannedChatType0Type1 | str):
        chat_status (bool | float | list[Any] | None | PostV1PersonasByIdResponse200ChatStatusType0Type1 | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['persona'] | Unset):
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
        bool | float | list[Any] | None | PostV1PersonasByIdResponse200CannedChatType0Type1 | str
    )
    chat_status: (
        bool | float | list[Any] | None | PostV1PersonasByIdResponse200ChatStatusType0Type1 | str
    )
    created: int
    updated: int
    object_: Literal["persona"] | Unset = UNSET
    owned_ecosystem_id: None | str | Unset = UNSET
    corpus_ecosystem_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_personas_by_id_response_200_canned_chat_type_0_type_1 import (
            PostV1PersonasByIdResponse200CannedChatType0Type1,
        )
        from ..models.post_v1_personas_by_id_response_200_chat_status_type_0_type_1 import (
            PostV1PersonasByIdResponse200ChatStatusType0Type1,
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
        if isinstance(self.canned_chat, PostV1PersonasByIdResponse200CannedChatType0Type1):
            canned_chat = self.canned_chat.to_dict()
        elif isinstance(self.canned_chat, list):
            canned_chat = self.canned_chat

        else:
            canned_chat = self.canned_chat

        chat_status: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.chat_status, PostV1PersonasByIdResponse200ChatStatusType0Type1):
            chat_status = self.chat_status.to_dict()
        elif isinstance(self.chat_status, list):
            chat_status = self.chat_status

        else:
            chat_status = self.chat_status

        created = self.created

        updated = self.updated

        object_ = self.object_

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
                "user_id": user_id,
                "author_kind": author_kind,
                "author_id": author_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "name": name,
                "description": description,
                "visibility": visibility,
                "model": model,
                "service_id": service_id,
                "app_id": app_id,
                "avatar_attachment_id": avatar_attachment_id,
                "model_prompt": model_prompt,
                "voice": voice,
                "character": character,
                "examples": examples,
                "canned_chat": canned_chat,
                "chat_status": chat_status,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if owned_ecosystem_id is not UNSET:
            field_dict["owned_ecosystem_id"] = owned_ecosystem_id
        if corpus_ecosystem_id is not UNSET:
            field_dict["corpus_ecosystem_id"] = corpus_ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_personas_by_id_response_200_canned_chat_type_0_type_1 import (
            PostV1PersonasByIdResponse200CannedChatType0Type1,
        )
        from ..models.post_v1_personas_by_id_response_200_chat_status_type_0_type_1 import (
            PostV1PersonasByIdResponse200ChatStatusType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        def _parse_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        user_id = _parse_user_id(d.pop("user_id"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

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

        service_id = _parse_service_id(d.pop("service_id"))

        def _parse_app_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        app_id = _parse_app_id(d.pop("app_id"))

        def _parse_avatar_attachment_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        avatar_attachment_id = _parse_avatar_attachment_id(d.pop("avatar_attachment_id"))

        model_prompt = d.pop("model_prompt")

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
            | PostV1PersonasByIdResponse200CannedChatType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                canned_chat_type_0_type_1 = (
                    PostV1PersonasByIdResponse200CannedChatType0Type1.from_dict(data)
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
                | PostV1PersonasByIdResponse200CannedChatType0Type1
                | str,
                data,
            )

        canned_chat = _parse_canned_chat(d.pop("canned_chat"))

        def _parse_chat_status(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1PersonasByIdResponse200ChatStatusType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                chat_status_type_0_type_1 = (
                    PostV1PersonasByIdResponse200ChatStatusType0Type1.from_dict(data)
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
                | PostV1PersonasByIdResponse200ChatStatusType0Type1
                | str,
                data,
            )

        chat_status = _parse_chat_status(d.pop("chat_status"))

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["persona"] | Unset, d.pop("object", UNSET))
        if object_ != "persona" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'persona', got '{object_}'")

        def _parse_owned_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        owned_ecosystem_id = _parse_owned_ecosystem_id(d.pop("owned_ecosystem_id", UNSET))

        def _parse_corpus_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        corpus_ecosystem_id = _parse_corpus_ecosystem_id(d.pop("corpus_ecosystem_id", UNSET))

        post_v1_personas_by_id_response_200 = cls(
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
            created=created,
            updated=updated,
            object_=object_,
            owned_ecosystem_id=owned_ecosystem_id,
            corpus_ecosystem_id=corpus_ecosystem_id,
        )

        return post_v1_personas_by_id_response_200
