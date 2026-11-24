from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ChatParticipantsAddRequest")


@_attrs_define
class ChatParticipantsAddRequest:
    """
    Attributes:
        user_ids (list[str] | Unset):
        persona_ids (list[str] | Unset):
    """

    user_ids: list[str] | Unset = UNSET
    persona_ids: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_ids: list[str] | Unset = UNSET
        if not isinstance(self.user_ids, Unset):
            user_ids = self.user_ids

        persona_ids: list[str] | Unset = UNSET
        if not isinstance(self.persona_ids, Unset):
            persona_ids = self.persona_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if user_ids is not UNSET:
            field_dict["user_ids"] = user_ids
        if persona_ids is not UNSET:
            field_dict["persona_ids"] = persona_ids

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_ids = cast(list[str], d.pop("user_ids", UNSET))

        persona_ids = cast(list[str], d.pop("persona_ids", UNSET))

        chat_participants_add_request = cls(
            user_ids=user_ids,
            persona_ids=persona_ids,
        )

        chat_participants_add_request.additional_properties = d
        return chat_participants_add_request

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
