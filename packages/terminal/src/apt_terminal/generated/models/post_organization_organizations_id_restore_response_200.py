from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_organization import RegistryOrganization


T = TypeVar("T", bound="PostOrganizationOrganizationsIdRestoreResponse200")


@_attrs_define
class PostOrganizationOrganizationsIdRestoreResponse200:
    """
    Attributes:
        organization (RegistryOrganization):
    """

    organization: RegistryOrganization
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        organization = self.organization.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "organization": organization,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_organization import RegistryOrganization

        d = dict(src_dict)
        organization = RegistryOrganization.from_dict(d.pop("organization"))

        post_organization_organizations_id_restore_response_200 = cls(
            organization=organization,
        )

        post_organization_organizations_id_restore_response_200.additional_properties = d
        return post_organization_organizations_id_restore_response_200

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
