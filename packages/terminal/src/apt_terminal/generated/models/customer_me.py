from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.customer_me_realm import CustomerMeRealm
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.customer_me_access import CustomerMeAccess
    from ..models.customer_me_sets_type_0 import CustomerMeSetsType0
    from ..models.customer_me_user import CustomerMeUser


T = TypeVar("T", bound="CustomerMe")


@_attrs_define
class CustomerMe:
    """
    Attributes:
        user (CustomerMeUser):
        ecosystem_id (str): The ecosystem the customer belongs to
        realm (CustomerMeRealm):
        access (CustomerMeAccess | Unset): The customer's product roles in its realm: each product feature area's item
            verbs as letters, e.g. { notes: 'CRUD' }. Absent where product roles do not apply.
        roles (list[str] | Unset): The slugs of the roles the customer holds in its realm, sorted. Absent with `access`.
        sets (CustomerMeSetsType0 | None | Unset): The customer's effective sets in its realm: null when the realm has
            no sets; the held set ids, the features they grant (all or read-only) and their limits; or { error: 'unresolved'
            } when the answer could not be computed while set enforcement is off (with it on, the request is refused 403).
    """

    user: CustomerMeUser
    ecosystem_id: str
    realm: CustomerMeRealm
    access: CustomerMeAccess | Unset = UNSET
    roles: list[str] | Unset = UNSET
    sets: CustomerMeSetsType0 | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.customer_me_sets_type_0 import CustomerMeSetsType0

        user = self.user.to_dict()

        ecosystem_id = self.ecosystem_id

        realm = self.realm.value

        access: dict[str, Any] | Unset = UNSET
        if not isinstance(self.access, Unset):
            access = self.access.to_dict()

        roles: list[str] | Unset = UNSET
        if not isinstance(self.roles, Unset):
            roles = self.roles

        sets: dict[str, Any] | None | Unset
        if isinstance(self.sets, Unset):
            sets = UNSET
        elif isinstance(self.sets, CustomerMeSetsType0):
            sets = self.sets.to_dict()
        else:
            sets = self.sets

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "user": user,
                "ecosystem_id": ecosystem_id,
                "realm": realm,
            }
        )
        if access is not UNSET:
            field_dict["access"] = access
        if roles is not UNSET:
            field_dict["roles"] = roles
        if sets is not UNSET:
            field_dict["sets"] = sets

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.customer_me_access import CustomerMeAccess
        from ..models.customer_me_sets_type_0 import CustomerMeSetsType0
        from ..models.customer_me_user import CustomerMeUser

        d = dict(src_dict)
        user = CustomerMeUser.from_dict(d.pop("user"))

        ecosystem_id = d.pop("ecosystem_id")

        realm = CustomerMeRealm(d.pop("realm"))

        _access = d.pop("access", UNSET)
        access: CustomerMeAccess | Unset
        if isinstance(_access, Unset):
            access = UNSET
        else:
            access = CustomerMeAccess.from_dict(_access)

        roles = cast(list[str], d.pop("roles", UNSET))

        def _parse_sets(data: object) -> CustomerMeSetsType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                sets_type_0 = CustomerMeSetsType0.from_dict(data)

                return sets_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(CustomerMeSetsType0 | None | Unset, data)

        sets = _parse_sets(d.pop("sets", UNSET))

        customer_me = cls(
            user=user,
            ecosystem_id=ecosystem_id,
            realm=realm,
            access=access,
            roles=roles,
            sets=sets,
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
