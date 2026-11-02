from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.persona_bootstrap_auth import PersonaBootstrapAuth
    from ..models.persona_bootstrap_bucket import PersonaBootstrapBucket
    from ..models.persona_bootstrap_chat import PersonaBootstrapChat
    from ..models.persona_bootstrap_memory import PersonaBootstrapMemory
    from ..models.persona_bootstrap_persona import PersonaBootstrapPersona
    from ..models.persona_bootstrap_prompt import PersonaBootstrapPrompt
    from ..models.persona_bootstrap_tool import PersonaBootstrapTool


T = TypeVar("T", bound="PersonaBootstrap")


@_attrs_define
class PersonaBootstrap:
    """Everything an implementation needs to start acting as its persona, in one read: who it is, what to say, what it may
    touch, and where to talk. Derived entirely from the bearer token — there are no parameters.

        Attributes:
            persona (PersonaBootstrapPersona):
            prompt (PersonaBootstrapPrompt):
            auth (PersonaBootstrapAuth): What the presented token is. A `visitor` token is the anonymous, read-shaped class.
            buckets (list[PersonaBootstrapBucket]):
            memory (PersonaBootstrapMemory): Both false for a visitor token.
            tools (list[PersonaBootstrapTool]):
            chat (PersonaBootstrapChat):
    """

    persona: PersonaBootstrapPersona
    prompt: PersonaBootstrapPrompt
    auth: PersonaBootstrapAuth
    buckets: list[PersonaBootstrapBucket]
    memory: PersonaBootstrapMemory
    tools: list[PersonaBootstrapTool]
    chat: PersonaBootstrapChat
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        persona = self.persona.to_dict()

        prompt = self.prompt.to_dict()

        auth = self.auth.to_dict()

        buckets = []
        for buckets_item_data in self.buckets:
            buckets_item = buckets_item_data.to_dict()
            buckets.append(buckets_item)

        memory = self.memory.to_dict()

        tools = []
        for tools_item_data in self.tools:
            tools_item = tools_item_data.to_dict()
            tools.append(tools_item)

        chat = self.chat.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "persona": persona,
                "prompt": prompt,
                "auth": auth,
                "buckets": buckets,
                "memory": memory,
                "tools": tools,
                "chat": chat,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_bootstrap_auth import PersonaBootstrapAuth
        from ..models.persona_bootstrap_bucket import PersonaBootstrapBucket
        from ..models.persona_bootstrap_chat import PersonaBootstrapChat
        from ..models.persona_bootstrap_memory import PersonaBootstrapMemory
        from ..models.persona_bootstrap_persona import PersonaBootstrapPersona
        from ..models.persona_bootstrap_prompt import PersonaBootstrapPrompt
        from ..models.persona_bootstrap_tool import PersonaBootstrapTool

        d = dict(src_dict)
        persona = PersonaBootstrapPersona.from_dict(d.pop("persona"))

        prompt = PersonaBootstrapPrompt.from_dict(d.pop("prompt"))

        auth = PersonaBootstrapAuth.from_dict(d.pop("auth"))

        buckets = []
        _buckets = d.pop("buckets")
        for buckets_item_data in _buckets:
            buckets_item = PersonaBootstrapBucket.from_dict(buckets_item_data)

            buckets.append(buckets_item)

        memory = PersonaBootstrapMemory.from_dict(d.pop("memory"))

        tools = []
        _tools = d.pop("tools")
        for tools_item_data in _tools:
            tools_item = PersonaBootstrapTool.from_dict(tools_item_data)

            tools.append(tools_item)

        chat = PersonaBootstrapChat.from_dict(d.pop("chat"))

        persona_bootstrap = cls(
            persona=persona,
            prompt=prompt,
            auth=auth,
            buckets=buckets,
            memory=memory,
            tools=tools,
            chat=chat,
        )

        persona_bootstrap.additional_properties = d
        return persona_bootstrap

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
