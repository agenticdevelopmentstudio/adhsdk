from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegistryEntriesByIdContactResponse201")


@_attrs_define
class PostV1RegistryEntriesByIdContactResponse201:
    """
    Attributes:
        chat_id (str): the hub DM chat the opening message was sent into
        object_ (Literal['registry_entry'] | Unset):
    """

    chat_id: str
    object_: Literal["registry_entry"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chat_id = self.chat_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chat_id": chat_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        chat_id = d.pop("chat_id")

        object_ = cast(Literal["registry_entry"] | Unset, d.pop("object", UNSET))
        if object_ != "registry_entry" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'registry_entry', got '{object_}'")

        post_v1_registry_entries_by_id_contact_response_201 = cls(
            chat_id=chat_id,
            object_=object_,
        )

        post_v1_registry_entries_by_id_contact_response_201.additional_properties = d
        return post_v1_registry_entries_by_id_contact_response_201

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
