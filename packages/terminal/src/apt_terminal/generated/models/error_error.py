from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.error_error_owned_item import ErrorErrorOwnedItem


T = TypeVar("T", bound="ErrorError")


@_attrs_define
class ErrorError:
    """
    Attributes:
        message (str | Unset):
        code (str | Unset):
        owned (list[ErrorErrorOwnedItem] | Unset): present when code is still_owns_data: the tables still owned, with
            counts
    """

    message: str | Unset = UNSET
    code: str | Unset = UNSET
    owned: list[ErrorErrorOwnedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        message = self.message

        code = self.code

        owned: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.owned, Unset):
            owned = []
            for owned_item_data in self.owned:
                owned_item = owned_item_data.to_dict()
                owned.append(owned_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if message is not UNSET:
            field_dict["message"] = message
        if code is not UNSET:
            field_dict["code"] = code
        if owned is not UNSET:
            field_dict["owned"] = owned

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.error_error_owned_item import ErrorErrorOwnedItem

        d = dict(src_dict)
        message = d.pop("message", UNSET)

        code = d.pop("code", UNSET)

        _owned = d.pop("owned", UNSET)
        owned: list[ErrorErrorOwnedItem] | Unset = UNSET
        if _owned is not UNSET:
            owned = []
            for owned_item_data in _owned:
                owned_item = ErrorErrorOwnedItem.from_dict(owned_item_data)

                owned.append(owned_item)

        error_error = cls(
            message=message,
            code=code,
            owned=owned,
        )

        error_error.additional_properties = d
        return error_error

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
