from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="RegistryProvisionedOrganizationHubData")


@_attrs_define
class RegistryProvisionedOrganizationHubData:
    """The org's Organization ecosystem: the child of its workspace that holds the org's own data — Notes, Research,
    Documents, Integrations, Planning, Storage

        Attributes:
            id (str):
            slug (str): Always `organization`
            rdid (str): ecosystem.<workspace path>.organization
    """

    id: str
    slug: str
    rdid: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        rdid = self.rdid

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "rdid": rdid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        rdid = d.pop("rdid")

        registry_provisioned_organization_hub_data = cls(
            id=id,
            slug=slug,
            rdid=rdid,
        )

        registry_provisioned_organization_hub_data.additional_properties = d
        return registry_provisioned_organization_hub_data

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
