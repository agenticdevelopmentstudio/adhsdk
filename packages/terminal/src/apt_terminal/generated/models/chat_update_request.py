from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ChatUpdateRequest")


@_attrs_define
class ChatUpdateRequest:
    """
    Attributes:
        name (str | Unset):
        photo_storage_key (None | str | Unset): null clears the photo
    """

    name: str | Unset = UNSET
    photo_storage_key: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        photo_storage_key: None | str | Unset
        if isinstance(self.photo_storage_key, Unset):
            photo_storage_key = UNSET
        else:
            photo_storage_key = self.photo_storage_key

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if photo_storage_key is not UNSET:
            field_dict["photo_storage_key"] = photo_storage_key

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        def _parse_photo_storage_key(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        photo_storage_key = _parse_photo_storage_key(d.pop("photo_storage_key", UNSET))

        chat_update_request = cls(
            name=name,
            photo_storage_key=photo_storage_key,
        )

        chat_update_request.additional_properties = d
        return chat_update_request

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
