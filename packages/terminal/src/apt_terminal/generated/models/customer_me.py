from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.customer_me_realm import CustomerMeRealm

if TYPE_CHECKING:
    from ..models.customer_me_user import CustomerMeUser


T = TypeVar("T", bound="CustomerMe")


@_attrs_define
class CustomerMe:
    """
    Attributes:
        user (CustomerMeUser):
        ecosystem_id (str): The ecosystem the customer belongs to
        realm (CustomerMeRealm):
    """

    user: CustomerMeUser
    ecosystem_id: str
    realm: CustomerMeRealm
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user = self.user.to_dict()

        ecosystem_id = self.ecosystem_id

        realm = self.realm.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "user": user,
                "ecosystem_id": ecosystem_id,
                "realm": realm,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.customer_me_user import CustomerMeUser

        d = dict(src_dict)
        user = CustomerMeUser.from_dict(d.pop("user"))

        ecosystem_id = d.pop("ecosystem_id")

        realm = CustomerMeRealm(d.pop("realm"))

        customer_me = cls(
            user=user,
            ecosystem_id=ecosystem_id,
            realm=realm,
        )

        customer_me.additional_properties = d
        return customer_me

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
