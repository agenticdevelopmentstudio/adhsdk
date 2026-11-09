from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.chat_definition_encryption_mode import ChatDefinitionEncryptionMode
from ..models.chat_definition_invite_policy import ChatDefinitionInvitePolicy
from ..models.chat_definition_persona_reply_policy import ChatDefinitionPersonaReplyPolicy
from ..models.chat_definition_state import ChatDefinitionState
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ChatDefinitionsResponse200DataItem")


@_attrs_define
class GetV1ChatDefinitionsResponse200DataItem:
    """
    Attributes:
        id (UUID): The built-in `direct` definition is always 00000000-0000-4000-8000-000000000001.
        ecosystem_id (None | str): Null for built-in `direct`.
        name (str):
        description (str):
        state (ChatDefinitionState): `archived` offers the definition for no new chats; existing chats keep working.
        max_participants (int): The developer’s ceiling. Must not exceed the system maximum (CHAT_MAX_PARTICIPANTS,
            default 32) when written; at use, the lower of the two applies.
        allow_invites (bool):
        invite_policy (ChatDefinitionInvitePolicy):
        user_configurable (bool): Whether participants may change the chat’s own settings.
        persona_reply_policy (ChatDefinitionPersonaReplyPolicy):
        allow_added_personas (bool): Whether participants may add personas beyond the definition’s own.
        persona_ids (list[UUID]): The personas every chat of this definition seats. Each must be usable by the caller,
            and they must leave at least one seat under maxParticipants.
        slug (str): Lowercase letters, digits and interior hyphens. `direct` is reserved, and a uuid-shaped slug is
            refused (a uuid in the path is always read as an id).
        encryption_mode (ChatDefinitionEncryptionMode): Read-only. Only `none` until end-to-end encryption lands.
        built_in (bool): True for `direct` (one-to-one DMs): read-only, present in every ecosystem.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str): Always null here: a deleted definition is never listed or returned.
        object_ (Literal['chat_definition'] | Unset):
    """

    id: UUID
    ecosystem_id: None | str
    name: str
    description: str
    state: ChatDefinitionState
    max_participants: int
    allow_invites: bool
    invite_policy: ChatDefinitionInvitePolicy
    user_configurable: bool
    persona_reply_policy: ChatDefinitionPersonaReplyPolicy
    allow_added_personas: bool
    persona_ids: list[UUID]
    slug: str
    encryption_mode: ChatDefinitionEncryptionMode
    built_in: bool
    created: int
    updated: int
    deleted_at: None | str
    object_: Literal["chat_definition"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id: None | str
        ecosystem_id = self.ecosystem_id

        name = self.name

        description = self.description

        state = self.state.value

        max_participants = self.max_participants

        allow_invites = self.allow_invites

        invite_policy = self.invite_policy.value

        user_configurable = self.user_configurable

        persona_reply_policy = self.persona_reply_policy.value

        allow_added_personas = self.allow_added_personas

        persona_ids = []
        for persona_ids_item_data in self.persona_ids:
            persona_ids_item = str(persona_ids_item_data)
            persona_ids.append(persona_ids_item)

        slug = self.slug

        encryption_mode = self.encryption_mode.value

        built_in = self.built_in

        created = self.created

        updated = self.updated

        deleted_at: None | str
        deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "name": name,
                "description": description,
                "state": state,
                "max_participants": max_participants,
                "allow_invites": allow_invites,
                "invite_policy": invite_policy,
                "user_configurable": user_configurable,
                "persona_reply_policy": persona_reply_policy,
                "allow_added_personas": allow_added_personas,
                "persona_ids": persona_ids,
                "slug": slug,
                "encryption_mode": encryption_mode,
                "built_in": built_in,
                "created": created,
                "updated": updated,
                "deleted_at": deleted_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        def _parse_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystem_id"))

        name = d.pop("name")

        description = d.pop("description")

        state = ChatDefinitionState(d.pop("state"))

        max_participants = d.pop("max_participants")

        allow_invites = d.pop("allow_invites")

        invite_policy = ChatDefinitionInvitePolicy(d.pop("invite_policy"))

        user_configurable = d.pop("user_configurable")

        persona_reply_policy = ChatDefinitionPersonaReplyPolicy(d.pop("persona_reply_policy"))

        allow_added_personas = d.pop("allow_added_personas")

        persona_ids = []
        _persona_ids = d.pop("persona_ids")
        for persona_ids_item_data in _persona_ids:
            persona_ids_item = UUID(persona_ids_item_data)

            persona_ids.append(persona_ids_item)

        slug = d.pop("slug")

        encryption_mode = ChatDefinitionEncryptionMode(d.pop("encryption_mode"))

        built_in = d.pop("built_in")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        object_ = cast(Literal["chat_definition"] | Unset, d.pop("object", UNSET))
        if object_ != "chat_definition" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'chat_definition', got '{object_}'")

        get_v1_chat_definitions_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            name=name,
            description=description,
            state=state,
            max_participants=max_participants,
            allow_invites=allow_invites,
            invite_policy=invite_policy,
            user_configurable=user_configurable,
            persona_reply_policy=persona_reply_policy,
            allow_added_personas=allow_added_personas,
            persona_ids=persona_ids,
            slug=slug,
            encryption_mode=encryption_mode,
            built_in=built_in,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            object_=object_,
        )

        get_v1_chat_definitions_response_200_data_item.additional_properties = d
        return get_v1_chat_definitions_response_200_data_item

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
