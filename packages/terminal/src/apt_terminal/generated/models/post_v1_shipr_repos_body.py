from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ShiprReposBody")


@_attrs_define
class PostV1ShiprReposBody:
    """
    Attributes:
        slug (str): owner/name on the forge.
        connection_id (str | Unset): A GitHub App installation belonging to the caller, from `GET /shipr/connections`.
            Omitted, the repository is read anonymously — status works, nothing that writes does.
        group_id (str | Unset): Where a FIRST registration files the mirrors it invents.
        main_branch (str | Unset):
        prepared_branch (str | Unset):
        deployment_owner (str | Unset): Where the ONE mirror goes when `.shipr` declares no shards. Read only on that
            fallback — a declared shard’s slug is never overridden, because the file and the form must not be able to say
            two different things.
        deployment_name (str | Unset): The mirror’s name on the same fallback. Defaults to `<name>-deployment`;
            overridable independently of the owner, because changing the org almost always keeps the name.
        provision (bool | Unset): Whether to GO AND MAKE IT, or only write down where it goes. `false` writes the rows
            synchronously, leaves `registeredAt` null and queues no run, so nothing is created on the forge under a name
            nobody has looked at yet; the operator then sets the org, the name and the environments and presses Provision,
            which is `POST /shipr/runs` with the same `register` operation. Defaults to true.
    """

    slug: str
    connection_id: str | Unset = UNSET
    group_id: str | Unset = UNSET
    main_branch: str | Unset = UNSET
    prepared_branch: str | Unset = UNSET
    deployment_owner: str | Unset = UNSET
    deployment_name: str | Unset = UNSET
    provision: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        connection_id = self.connection_id

        group_id = self.group_id

        main_branch = self.main_branch

        prepared_branch = self.prepared_branch

        deployment_owner = self.deployment_owner

        deployment_name = self.deployment_name

        provision = self.provision

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
            }
        )
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id
        if group_id is not UNSET:
            field_dict["group_id"] = group_id
        if main_branch is not UNSET:
            field_dict["main_branch"] = main_branch
        if prepared_branch is not UNSET:
            field_dict["prepared_branch"] = prepared_branch
        if deployment_owner is not UNSET:
            field_dict["deployment_owner"] = deployment_owner
        if deployment_name is not UNSET:
            field_dict["deployment_name"] = deployment_name
        if provision is not UNSET:
            field_dict["provision"] = provision

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        connection_id = d.pop("connection_id", UNSET)

        group_id = d.pop("group_id", UNSET)

        main_branch = d.pop("main_branch", UNSET)

        prepared_branch = d.pop("prepared_branch", UNSET)

        deployment_owner = d.pop("deployment_owner", UNSET)

        deployment_name = d.pop("deployment_name", UNSET)

        provision = d.pop("provision", UNSET)

        post_v1_shipr_repos_body = cls(
            slug=slug,
            connection_id=connection_id,
            group_id=group_id,
            main_branch=main_branch,
            prepared_branch=prepared_branch,
            deployment_owner=deployment_owner,
            deployment_name=deployment_name,
            provision=provision,
        )

        post_v1_shipr_repos_body.additional_properties = d
        return post_v1_shipr_repos_body

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
