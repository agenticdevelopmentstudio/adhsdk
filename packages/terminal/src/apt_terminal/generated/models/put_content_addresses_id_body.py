from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentAddressesIdBody")


@_attrs_define
class PutContentAddressesIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        label (str | Unset):
        line1 (str | Unset):
        line2 (str | Unset):
        city (str | Unset):
        region (str | Unset):
        postal_code (str | Unset):
        country (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    label: str | Unset = UNSET
    line1: str | Unset = UNSET
    line2: str | Unset = UNSET
    city: str | Unset = UNSET
    region: str | Unset = UNSET
    postal_code: str | Unset = UNSET
    country: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        label = self.label

        line1 = self.line1

        line2 = self.line2

        city = self.city

        region = self.region

        postal_code = self.postal_code

        country = self.country

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if label is not UNSET:
            field_dict["label"] = label
        if line1 is not UNSET:
            field_dict["line1"] = line1
        if line2 is not UNSET:
            field_dict["line2"] = line2
        if city is not UNSET:
            field_dict["city"] = city
        if region is not UNSET:
            field_dict["region"] = region
        if postal_code is not UNSET:
            field_dict["postalCode"] = postal_code
        if country is not UNSET:
            field_dict["country"] = country

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        label = d.pop("label", UNSET)

        line1 = d.pop("line1", UNSET)

        line2 = d.pop("line2", UNSET)

        city = d.pop("city", UNSET)

        region = d.pop("region", UNSET)

        postal_code = d.pop("postalCode", UNSET)

        country = d.pop("country", UNSET)

        put_content_addresses_id_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            label=label,
            line1=line1,
            line2=line2,
            city=city,
            region=region,
            postal_code=postal_code,
            country=country,
        )

        return put_content_addresses_id_body
