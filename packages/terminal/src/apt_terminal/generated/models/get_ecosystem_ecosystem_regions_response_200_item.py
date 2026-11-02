from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetEcosystemEcosystemRegionsResponse200Item")


@_attrs_define
class GetEcosystemEcosystemRegionsResponse200Item:
    """
    Attributes:
        id (str):
        display_name (str):
        postgres_host (str):
        railway_service_id (str):
        is_default_for_new_projects (bool):
        created_at (str):
    """

    id: str
    display_name: str
    postgres_host: str
    railway_service_id: str
    is_default_for_new_projects: bool
    created_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        display_name = self.display_name

        postgres_host = self.postgres_host

        railway_service_id = self.railway_service_id

        is_default_for_new_projects = self.is_default_for_new_projects

        created_at = self.created_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "displayName": display_name,
                "postgresHost": postgres_host,
                "railwayServiceId": railway_service_id,
                "isDefaultForNewProjects": is_default_for_new_projects,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        display_name = d.pop("displayName")

        postgres_host = d.pop("postgresHost")

        railway_service_id = d.pop("railwayServiceId")

        is_default_for_new_projects = d.pop("isDefaultForNewProjects")

        created_at = d.pop("createdAt")

        get_ecosystem_ecosystem_regions_response_200_item = cls(
            id=id,
            display_name=display_name,
            postgres_host=postgres_host,
            railway_service_id=railway_service_id,
            is_default_for_new_projects=is_default_for_new_projects,
            created_at=created_at,
        )

        return get_ecosystem_ecosystem_regions_response_200_item
