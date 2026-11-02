from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.put_ecosystem_applications_app_id_schema_grants_body_grants_item import (
        PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItem,
    )


T = TypeVar("T", bound="PutEcosystemApplicationsAppIdSchemaGrantsBody")


@_attrs_define
class PutEcosystemApplicationsAppIdSchemaGrantsBody:
    """
    Attributes:
        grants (list[PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItem]):
    """

    grants: list[PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        grants = []
        for grants_item_data in self.grants:
            grants_item = grants_item_data.to_dict()
            grants.append(grants_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "grants": grants,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_ecosystem_applications_app_id_schema_grants_body_grants_item import (
            PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItem,
        )

        d = dict(src_dict)
        grants = []
        _grants = d.pop("grants")
        for grants_item_data in _grants:
            grants_item = PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItem.from_dict(
                grants_item_data
            )

            grants.append(grants_item)

        put_ecosystem_applications_app_id_schema_grants_body = cls(
            grants=grants,
        )

        put_ecosystem_applications_app_id_schema_grants_body.additional_properties = d
        return put_ecosystem_applications_app_id_schema_grants_body

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
