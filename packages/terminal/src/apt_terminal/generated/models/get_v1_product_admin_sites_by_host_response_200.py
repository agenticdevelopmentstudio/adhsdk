from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ProductAdminSitesByHostResponse200")


@_attrs_define
class GetV1ProductAdminSitesByHostResponse200:
    """
    Attributes:
        ecosystem_id (UUID):
        name (str): The product's name.
        client_id (str): The client the site starts a sign-in with.
        issuer (None | str): The Hydra issuer URL.
        object_ (Literal['product_admin_site'] | Unset):
    """

    ecosystem_id: UUID
    name: str
    client_id: str
    issuer: None | str
    object_: Literal["product_admin_site"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = str(self.ecosystem_id)

        name = self.name

        client_id = self.client_id

        issuer: None | str
        issuer = self.issuer

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem_id": ecosystem_id,
                "name": name,
                "client_id": client_id,
                "issuer": issuer,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = UUID(d.pop("ecosystem_id"))

        name = d.pop("name")

        client_id = d.pop("client_id")

        def _parse_issuer(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        issuer = _parse_issuer(d.pop("issuer"))

        object_ = cast(Literal["product_admin_site"] | Unset, d.pop("object", UNSET))
        if object_ != "product_admin_site" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'product_admin_site', got '{object_}'")

        get_v1_product_admin_sites_by_host_response_200 = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            client_id=client_id,
            issuer=issuer,
            object_=object_,
        )

        get_v1_product_admin_sites_by_host_response_200.additional_properties = d
        return get_v1_product_admin_sites_by_host_response_200

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
