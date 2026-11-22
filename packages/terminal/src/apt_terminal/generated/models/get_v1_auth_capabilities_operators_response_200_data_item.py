from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AuthCapabilitiesOperatorsResponse200DataItem")


@_attrs_define
class GetV1AuthCapabilitiesOperatorsResponse200DataItem:
    """
    Attributes:
        id (str):
        email (str):
        name (str):
        created (int): Unix timestamp, in seconds.
        holds_admin (bool):
        object_ (Literal['auth.operator'] | Unset):
    """

    id: str
    email: str
    name: str
    created: int
    holds_admin: bool
    object_: Literal["auth.operator"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        email = self.email

        name = self.name

        created = self.created

        holds_admin = self.holds_admin

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "email": email,
                "name": name,
                "created": created,
                "holds_admin": holds_admin,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        email = d.pop("email")

        name = d.pop("name")

        created = d.pop("created")

        holds_admin = d.pop("holds_admin")

        object_ = cast(Literal["auth.operator"] | Unset, d.pop("object", UNSET))
        if object_ != "auth.operator" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'auth.operator', got '{object_}'")

        get_v1_auth_capabilities_operators_response_200_data_item = cls(
            id=id,
            email=email,
            name=name,
            created=created,
            holds_admin=holds_admin,
            object_=object_,
        )

        get_v1_auth_capabilities_operators_response_200_data_item.additional_properties = d
        return get_v1_auth_capabilities_operators_response_200_data_item

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
