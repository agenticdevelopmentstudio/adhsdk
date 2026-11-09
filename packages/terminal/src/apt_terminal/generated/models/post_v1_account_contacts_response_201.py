from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.contact_method_type import ContactMethodType
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccountContactsResponse201")


@_attrs_define
class PostV1AccountContactsResponse201:
    """
    Attributes:
        id (str):
        type_ (ContactMethodType):
        value (str):
        verified (bool):
        is_primary (bool):
        created (int | Unset): Unix timestamp, in seconds.
        object_ (Literal['account.contact'] | Unset):
    """

    id: str
    type_: ContactMethodType
    value: str
    verified: bool
    is_primary: bool
    created: int | Unset = UNSET
    object_: Literal["account.contact"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        type_ = self.type_.value

        value = self.value

        verified = self.verified

        is_primary = self.is_primary

        created = self.created

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["account.contact"] | Unset, d.pop("object", UNSET))
        if object_ != "account.contact" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'account.contact', got '{object_}'")

        post_v1_account_contacts_response_201 = cls(
            id=id,
            type_=type_,
            value=value,
            verified=verified,
            is_primary=is_primary,
            created=created,
            object_=object_,
        )

        post_v1_account_contacts_response_201.additional_properties = d
        return post_v1_account_contacts_response_201

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
