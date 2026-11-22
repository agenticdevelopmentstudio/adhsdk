from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="ProductAdminSiteLookup")


@_attrs_define
class ProductAdminSiteLookup:
    """
    Attributes:
        ecosystem_id (UUID):
        name (str): The product's name.
        client_id (str): The client the site starts a sign-in with.
        issuer (None | str): The Hydra issuer URL.
    """

    ecosystem_id: UUID
    name: str
    client_id: str
    issuer: None | str

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = str(self.ecosystem_id)

        name = self.name

        client_id = self.client_id

        issuer: None | str
        issuer = self.issuer

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "ecosystem_id": ecosystem_id,
                "name": name,
                "client_id": client_id,
                "issuer": issuer,
            }
        )

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

        product_admin_site_lookup = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            client_id=client_id,
            issuer=issuer,
        )

        return product_admin_site_lookup
