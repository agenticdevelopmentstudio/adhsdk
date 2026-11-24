from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegionsResponse201")


@_attrs_define
class PostV1RegionsResponse201:
    """
    Attributes:
        id (str):
        display_name (str):
        postgres_host (str):
        railway_service_id (str):
        is_default_for_new_projects (bool):
        created (int): Unix timestamp, in seconds.
        object_ (Literal['region'] | Unset):
    """

    id: str
    display_name: str
    postgres_host: str
    railway_service_id: str
    is_default_for_new_projects: bool
    created: int
    object_: Literal["region"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        display_name = self.display_name

        postgres_host = self.postgres_host

        railway_service_id = self.railway_service_id

        is_default_for_new_projects = self.is_default_for_new_projects

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "display_name": display_name,
                "postgres_host": postgres_host,
                "railway_service_id": railway_service_id,
                "is_default_for_new_projects": is_default_for_new_projects,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        display_name = d.pop("display_name")

        postgres_host = d.pop("postgres_host")

        railway_service_id = d.pop("railway_service_id")

        is_default_for_new_projects = d.pop("is_default_for_new_projects")

        created = d.pop("created")

        object_ = cast(Literal["region"] | Unset, d.pop("object", UNSET))
        if object_ != "region" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'region', got '{object_}'")

        post_v1_regions_response_201 = cls(
            id=id,
            display_name=display_name,
            postgres_host=postgres_host,
            railway_service_id=railway_service_id,
            is_default_for_new_projects=is_default_for_new_projects,
            created=created,
            object_=object_,
        )

        return post_v1_regions_response_201
