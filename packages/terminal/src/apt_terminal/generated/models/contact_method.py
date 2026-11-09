from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.contact_method_type import ContactMethodType
from ..types import UNSET, Unset

T = TypeVar("T", bound="ContactMethod")


@_attrs_define
class ContactMethod:
    """
    Attributes:
        id (str):
        type_ (ContactMethodType):
        value (str):
        verified (bool):
        is_primary (bool):
        created (int | Unset): Unix timestamp, in seconds.
    """

    id: str
    type_: ContactMethodType
    value: str
    verified: bool
    is_primary: bool
    created: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        type_ = self.type_.value

        value = self.value

        verified = self.verified

        is_primary = self.is_primary

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "type": type_,
                "value": value,
                "verified": verified,
                "is_primary": is_primary,
            }
        )
        if created is not UNSET:
            field_dict["created"] = created

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        type_ = ContactMethodType(d.pop("type"))

        value = d.pop("value")

        verified = d.pop("verified")

        is_primary = d.pop("is_primary")

        created = d.pop("created", UNSET)

        contact_method = cls(
            id=id,
            type_=type_,
            value=value,
            verified=verified,
            is_primary=is_primary,
            created=created,
        )

        contact_method.additional_properties = d
        return contact_method

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
