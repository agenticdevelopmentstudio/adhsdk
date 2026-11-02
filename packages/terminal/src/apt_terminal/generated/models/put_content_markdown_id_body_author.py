from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentMarkdownIdBodyAuthor")


@_attrs_define
class PutContentMarkdownIdBodyAuthor:
    """Author of this revision; omit to attribute to the calling customer. customer/user are pinned to the caller; other
    types are caller-asserted (unverified).

        Attributes:
            type_ (str | Unset): Lower-cased. e.g. 'customer', 'user', 'persona', 'agent', 'system'.
            id (str | Unset): Id within that type's namespace (ignored for customer/user — pinned to the caller).
            name (str | Unset): Display label; ignored for customer/user (taken from the principal).
    """

    type_: str | Unset = UNSET
    id: str | Unset = UNSET
    name: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_

        id = self.id

        name = self.name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if type_ is not UNSET:
            field_dict["type"] = type_
        if id is not UNSET:
            field_dict["id"] = id
        if name is not UNSET:
            field_dict["name"] = name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        type_ = d.pop("type", UNSET)

        id = d.pop("id", UNSET)

        name = d.pop("name", UNSET)

        put_content_markdown_id_body_author = cls(
            type_=type_,
            id=id,
            name=name,
        )

        put_content_markdown_id_body_author.additional_properties = d
        return put_content_markdown_id_body_author

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
