from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_ecosystem import RegistryEcosystem
    from ..models.registry_namespace import RegistryNamespace
    from ..models.registry_organization import RegistryOrganization
    from ..models.registry_provisioned_organization_hub_data import (
        RegistryProvisionedOrganizationHubData,
    )


T = TypeVar("T", bound="RegistryProvisionedOrganization")


@_attrs_define
class RegistryProvisionedOrganization:
    """
    Attributes:
        organization (RegistryOrganization):
        namespace (RegistryNamespace):
        team_id (str): The provisioned admin team id
        ecosystem (RegistryEcosystem):
        hub_data (RegistryProvisionedOrganizationHubData): The org's Organization ecosystem: the child of its workspace
            that holds the org's own data — Notes, Research, Documents, Integrations, Planning, Storage
    """

    organization: RegistryOrganization
    namespace: RegistryNamespace
    team_id: str
    ecosystem: RegistryEcosystem
    hub_data: RegistryProvisionedOrganizationHubData
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        organization = self.organization.to_dict()

        namespace = self.namespace.to_dict()

        team_id = self.team_id

        ecosystem = self.ecosystem.to_dict()

        hub_data = self.hub_data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "organization": organization,
                "namespace": namespace,
                "team_id": team_id,
                "ecosystem": ecosystem,
                "hub_data": hub_data,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_ecosystem import RegistryEcosystem
        from ..models.registry_namespace import RegistryNamespace
        from ..models.registry_organization import RegistryOrganization
        from ..models.registry_provisioned_organization_hub_data import (
            RegistryProvisionedOrganizationHubData,
        )

        d = dict(src_dict)
        organization = RegistryOrganization.from_dict(d.pop("organization"))

        namespace = RegistryNamespace.from_dict(d.pop("namespace"))

        team_id = d.pop("team_id")

        ecosystem = RegistryEcosystem.from_dict(d.pop("ecosystem"))

        hub_data = RegistryProvisionedOrganizationHubData.from_dict(d.pop("hub_data"))

        registry_provisioned_organization = cls(
            organization=organization,
            namespace=namespace,
            team_id=team_id,
            ecosystem=ecosystem,
            hub_data=hub_data,
        )

        registry_provisioned_organization.additional_properties = d
        return registry_provisioned_organization

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
