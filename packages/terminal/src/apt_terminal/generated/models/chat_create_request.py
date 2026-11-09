from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ChatCreateRequest")


@_attrs_define
class ChatCreateRequest:
    """
    Attributes:
        definition (str): The definition’s id or slug
        user_ids (list[str] | Unset):
        persona_ids (list[str] | Unset):
        name (str | Unset): Defaults to the definition’s name
    """

    definition: str
    user_ids: list[str] | Unset = UNSET
    persona_ids: list[str] | Unset = UNSET
    name: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        definition = self.definition

        user_ids: list[str] | Unset = UNSET
        if not isinstance(self.user_ids, Unset):
            user_ids = self.user_ids

        persona_ids: list[str] | Unset = UNSET
        if not isinstance(self.persona_ids, Unset):
            persona_ids = self.persona_ids

        name = self.name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "definition": definition,
            }
        )
        if user_ids is not UNSET:
            field_dict["user_ids"] = user_ids
        if persona_ids is not UNSET:
            field_dict["persona_ids"] = persona_ids
        if name is not UNSET:
            field_dict["name"] = name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        definition = d.pop("definition")

        user_ids = cast(list[str], d.pop("user_ids", UNSET))

        persona_ids = cast(list[str], d.pop("persona_ids", UNSET))

        name = d.pop("name", UNSET)

        chat_create_request = cls(
            definition=definition,
            user_ids=user_ids,
            persona_ids=persona_ids,
            name=name,
        )

        chat_create_request.additional_properties = d
        return chat_create_request

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
