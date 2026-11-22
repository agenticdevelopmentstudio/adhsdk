from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.product_customer_role import ProductCustomerRole


T = TypeVar("T", bound="ProductCustomer")


@_attrs_define
class ProductCustomer:
    """
    Attributes:
        id (UUID):
        email (None | str):
        display_name (None | str):
        avatar_url (str):
        external_id (None | str):
        created (int): Unix timestamp, in seconds.
        last_active_day (datetime.date | None): The last UTC day with usage in this product.
        roles (list[ProductCustomerRole]): The product roles held product-wide.
        sets (list[UUID]): The ids of the sets granted and not revoked.
        storage_bytes (int):
        quota_bytes (int):
        paused (bool):
    """

    id: UUID
    email: None | str
    display_name: None | str
    avatar_url: str
    external_id: None | str
    created: int
    last_active_day: datetime.date | None
    roles: list[ProductCustomerRole]
    sets: list[UUID]
    storage_bytes: int
    quota_bytes: int
    paused: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        email: None | str
        email = self.email

        display_name: None | str
        display_name = self.display_name

        avatar_url = self.avatar_url

        external_id: None | str
        external_id = self.external_id

        created = self.created

        last_active_day: None | str
        if isinstance(self.last_active_day, datetime.date):
            last_active_day = self.last_active_day.isoformat()
        else:
            last_active_day = self.last_active_day

        roles = []
        for roles_item_data in self.roles:
            roles_item = roles_item_data.to_dict()
            roles.append(roles_item)

        sets = []
        for sets_item_data in self.sets:
            sets_item = str(sets_item_data)
            sets.append(sets_item)

        storage_bytes = self.storage_bytes

        quota_bytes = self.quota_bytes

        paused = self.paused

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "email": email,
                "display_name": display_name,
                "avatar_url": avatar_url,
                "external_id": external_id,
                "created": created,
                "last_active_day": last_active_day,
                "roles": roles,
                "sets": sets,
                "storage_bytes": storage_bytes,
                "quota_bytes": quota_bytes,
                "paused": paused,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.product_customer_role import ProductCustomerRole

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        def _parse_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        email = _parse_email(d.pop("email"))

        def _parse_display_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        display_name = _parse_display_name(d.pop("display_name"))

        avatar_url = d.pop("avatar_url")

        def _parse_external_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_id = _parse_external_id(d.pop("external_id"))

        created = d.pop("created")

        def _parse_last_active_day(data: object) -> datetime.date | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                last_active_day_type_0 = datetime.date.fromisoformat(data)

                return last_active_day_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.date | None, data)

        last_active_day = _parse_last_active_day(d.pop("last_active_day"))

        roles = []
        _roles = d.pop("roles")
        for roles_item_data in _roles:
            roles_item = ProductCustomerRole.from_dict(roles_item_data)

            roles.append(roles_item)

        sets = []
        _sets = d.pop("sets")
        for sets_item_data in _sets:
            sets_item = UUID(sets_item_data)

            sets.append(sets_item)

        storage_bytes = d.pop("storage_bytes")

        quota_bytes = d.pop("quota_bytes")

        paused = d.pop("paused")

        product_customer = cls(
            id=id,
            email=email,
            display_name=display_name,
            avatar_url=avatar_url,
            external_id=external_id,
            created=created,
            last_active_day=last_active_day,
            roles=roles,
            sets=sets,
            storage_bytes=storage_bytes,
            quota_bytes=quota_bytes,
            paused=paused,
        )

        product_customer.additional_properties = d
        return product_customer

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
