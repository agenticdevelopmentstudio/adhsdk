from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.get_ecosystem_applications_app_id_schema_grants_response_200_grants_item import (
        GetEcosystemApplicationsAppIdSchemaGrantsResponse200GrantsItem,
    )


T = TypeVar("T", bound="GetEcosystemApplicationsAppIdSchemaGrantsResponse200")


@_attrs_define
class GetEcosystemApplicationsAppIdSchemaGrantsResponse200:
    """
    Attributes:
        grants (list[GetEcosystemApplicationsAppIdSchemaGrantsResponse200GrantsItem]):
    """

    grants: list[GetEcosystemApplicationsAppIdSchemaGrantsResponse200GrantsItem]
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
        from ..models.get_ecosystem_applications_app_id_schema_grants_response_200_grants_item import (
            GetEcosystemApplicationsAppIdSchemaGrantsResponse200GrantsItem,
        )

        d = dict(src_dict)
        grants = []
        _grants = d.pop("grants")
        for grants_item_data in _grants:
            grants_item = GetEcosystemApplicationsAppIdSchemaGrantsResponse200GrantsItem.from_dict(
                grants_item_data
            )

            grants.append(grants_item)

        get_ecosystem_applications_app_id_schema_grants_response_200 = cls(
            grants=grants,
        )

        get_ecosystem_applications_app_id_schema_grants_response_200.additional_properties = d
        return get_ecosystem_applications_app_id_schema_grants_response_200

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
