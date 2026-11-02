from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaBootstrapPrompt")


@_attrs_define
class PersonaBootstrapPrompt:
    """
    Attributes:
        system (str):
        voice (None | str):
        character (None | str):
    """

    system: str
    voice: None | str
    character: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        system = self.system

        voice: None | str
        voice = self.voice

        character: None | str
        character = self.character

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "system": system,
                "voice": voice,
                "character": character,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        system = d.pop("system")

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

        persona_bootstrap_prompt = cls(
            system=system,
            voice=voice,
            character=character,
        )

        persona_bootstrap_prompt.additional_properties = d
        return persona_bootstrap_prompt

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
