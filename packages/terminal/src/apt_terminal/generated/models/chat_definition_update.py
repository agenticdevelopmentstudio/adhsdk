from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

from ..models.chat_definition_update_invite_policy import ChatDefinitionUpdateInvitePolicy
from ..models.chat_definition_update_persona_reply_policy import (
    ChatDefinitionUpdatePersonaReplyPolicy,
)
from ..models.chat_definition_update_state import ChatDefinitionUpdateState
from ..types import UNSET, Unset

T = TypeVar("T", bound="ChatDefinitionUpdate")


@_attrs_define
class ChatDefinitionUpdate:
    """Partial. `personaIds`, when present, REPLACES the set.

    Attributes:
        name (str | Unset):
        description (str | Unset):
        state (ChatDefinitionUpdateState | Unset): `archived` offers the definition for no new chats; existing chats
            keep working.
        max_participants (int | Unset): The developer’s ceiling. Must not exceed the system maximum
            (CHAT_MAX_PARTICIPANTS, default 32) when written; at use, the lower of the two applies.
        allow_invites (bool | Unset):
        invite_policy (ChatDefinitionUpdateInvitePolicy | Unset):
        user_configurable (bool | Unset): Whether participants may change the chat’s own settings.
        persona_reply_policy (ChatDefinitionUpdatePersonaReplyPolicy | Unset):
        allow_added_personas (bool | Unset): Whether participants may add personas beyond the definition’s own.
        persona_ids (list[UUID] | Unset): The personas every chat of this definition seats. Each must be usable by the
            caller, and they must leave at least one seat under maxParticipants.
        slug (str | Unset): Lowercase letters, digits and interior hyphens. `direct` is reserved, and a uuid-shaped slug
            is refused (a uuid in the path is always read as an id).
    """

    name: str | Unset = UNSET
    description: str | Unset = UNSET
    state: ChatDefinitionUpdateState | Unset = UNSET
    max_participants: int | Unset = UNSET
    allow_invites: bool | Unset = UNSET
    invite_policy: ChatDefinitionUpdateInvitePolicy | Unset = UNSET
    user_configurable: bool | Unset = UNSET
    persona_reply_policy: ChatDefinitionUpdatePersonaReplyPolicy | Unset = UNSET
    allow_added_personas: bool | Unset = UNSET
    persona_ids: list[UUID] | Unset = UNSET
    slug: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        max_participants = self.max_participants

        allow_invites = self.allow_invites

        invite_policy: str | Unset = UNSET
        if not isinstance(self.invite_policy, Unset):
            invite_policy = self.invite_policy.value

        user_configurable = self.user_configurable

        persona_reply_policy: str | Unset = UNSET
        if not isinstance(self.persona_reply_policy, Unset):
            persona_reply_policy = self.persona_reply_policy.value

        allow_added_personas = self.allow_added_personas

        persona_ids: list[str] | Unset = UNSET
        if not isinstance(self.persona_ids, Unset):
            persona_ids = []
            for persona_ids_item_data in self.persona_ids:
                persona_ids_item = str(persona_ids_item_data)
                persona_ids.append(persona_ids_item)

        slug = self.slug

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if state is not UNSET:
            field_dict["state"] = state
        if max_participants is not UNSET:
            field_dict["maxParticipants"] = max_participants
        if allow_invites is not UNSET:
            field_dict["allowInvites"] = allow_invites
        if invite_policy is not UNSET:
            field_dict["invitePolicy"] = invite_policy
        if user_configurable is not UNSET:
            field_dict["userConfigurable"] = user_configurable
        if persona_reply_policy is not UNSET:
            field_dict["personaReplyPolicy"] = persona_reply_policy
        if allow_added_personas is not UNSET:
            field_dict["allowAddedPersonas"] = allow_added_personas
        if persona_ids is not UNSET:
            field_dict["personaIds"] = persona_ids
        if slug is not UNSET:
            field_dict["slug"] = slug

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        _state = d.pop("state", UNSET)
        state: ChatDefinitionUpdateState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = ChatDefinitionUpdateState(_state)

        max_participants = d.pop("maxParticipants", UNSET)

        allow_invites = d.pop("allowInvites", UNSET)

        _invite_policy = d.pop("invitePolicy", UNSET)
        invite_policy: ChatDefinitionUpdateInvitePolicy | Unset
        if isinstance(_invite_policy, Unset):
            invite_policy = UNSET
        else:
            invite_policy = ChatDefinitionUpdateInvitePolicy(_invite_policy)

        user_configurable = d.pop("userConfigurable", UNSET)

        _persona_reply_policy = d.pop("personaReplyPolicy", UNSET)
        persona_reply_policy: ChatDefinitionUpdatePersonaReplyPolicy | Unset
        if isinstance(_persona_reply_policy, Unset):
            persona_reply_policy = UNSET
        else:
            persona_reply_policy = ChatDefinitionUpdatePersonaReplyPolicy(_persona_reply_policy)

        allow_added_personas = d.pop("allowAddedPersonas", UNSET)

        _persona_ids = d.pop("personaIds", UNSET)
        persona_ids: list[UUID] | Unset = UNSET
        if _persona_ids is not UNSET:
            persona_ids = []
            for persona_ids_item_data in _persona_ids:
                persona_ids_item = UUID(persona_ids_item_data)

                persona_ids.append(persona_ids_item)

        slug = d.pop("slug", UNSET)

        chat_definition_update = cls(
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
        )

        return chat_definition_update
