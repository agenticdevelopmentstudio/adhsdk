from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegionsBody")


@_attrs_define
class PostV1RegionsBody:
    """
    Attributes:
        display_name (str):
        postgres_host (str | Unset):
        railway_service_id (str | Unset):
        is_default_for_new_projects (bool | Unset):
    """

    display_name: str
    postgres_host: str | Unset = UNSET
    railway_service_id: str | Unset = UNSET
    is_default_for_new_projects: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        display_name = self.display_name

        postgres_host = self.postgres_host

        railway_service_id = self.railway_service_id

        is_default_for_new_projects = self.is_default_for_new_projects

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "display_name": display_name,
            }
        )
        if postgres_host is not UNSET:
            field_dict["postgres_host"] = postgres_host
        if railway_service_id is not UNSET:
            field_dict["railway_service_id"] = railway_service_id
        if is_default_for_new_projects is not UNSET:
            field_dict["is_default_for_new_projects"] = is_default_for_new_projects

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        display_name = d.pop("display_name")

        postgres_host = d.pop("postgres_host", UNSET)

        railway_service_id = d.pop("railway_service_id", UNSET)

        is_default_for_new_projects = d.pop("is_default_for_new_projects", UNSET)

        post_v1_regions_body = cls(
            display_name=display_name,
            postgres_host=postgres_host,
            railway_service_id=railway_service_id,
            is_default_for_new_projects=is_default_for_new_projects,
        )

        return post_v1_regions_body
