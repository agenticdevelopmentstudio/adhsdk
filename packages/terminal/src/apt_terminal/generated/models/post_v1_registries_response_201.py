from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_owner_kind import RegistryOwnerKind
from ..models.registry_submission_policy import RegistrySubmissionPolicy
from ..models.registry_visibility import RegistryVisibility
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegistriesResponse201")


@_attrs_define
class PostV1RegistriesResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (RegistryOwnerKind):
        owner_id (str):
        slug (str): globally unique path segment on the registries site
        name (str):
        purpose (str): the one-line "what this registry is for"
        description (str):
        category_root (str): the industry half of <industry>.<service-type>
        entry_term (str): what this registry calls an entry, e.g. "coach"
        tags (list[str]): Discovery labels the owner puts on the registry. A SET: the server trims each label and drops
            duplicates, so what comes back is not necessarily what was sent.
        visibility (RegistryVisibility):
        submission_policy (RegistrySubmissionPolicy):
        services_enabled (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        bound_site_id (None | str | Unset): a fleet SITE SLUG this registry is bound to; set by platform admin only,
            never via this API
        deleted_at (None | str | Unset):
        object_ (Literal['registry'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: RegistryOwnerKind
    owner_id: str
    slug: str
    name: str
    purpose: str
    description: str
    category_root: str
    entry_term: str
    tags: list[str]
    visibility: RegistryVisibility
    submission_policy: RegistrySubmissionPolicy
    services_enabled: bool
    created: int
    updated: int
    sync_version: int
    bound_site_id: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    object_: Literal["registry"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        slug = self.slug

        name = self.name

        purpose = self.purpose

        description = self.description

        category_root = self.category_root

        entry_term = self.entry_term

        tags = self.tags

        visibility = self.visibility.value

        submission_policy = self.submission_policy.value

        services_enabled = self.services_enabled

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        bound_site_id: None | str | Unset
        if isinstance(self.bound_site_id, Unset):
            bound_site_id = UNSET
        else:
            bound_site_id = self.bound_site_id

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "name": name,
                "purpose": purpose,
                "description": description,
                "category_root": category_root,
                "entry_term": entry_term,
                "tags": tags,
                "visibility": visibility,
                "submission_policy": submission_policy,
                "services_enabled": services_enabled,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
            }
        )
        if bound_site_id is not UNSET:
            field_dict["bound_site_id"] = bound_site_id
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = RegistryOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        slug = d.pop("slug")

        name = d.pop("name")

        purpose = d.pop("purpose")

        description = d.pop("description")

        category_root = d.pop("category_root")

        entry_term = d.pop("entry_term")

        tags = cast(list[str], d.pop("tags"))

        visibility = RegistryVisibility(d.pop("visibility"))

        submission_policy = RegistrySubmissionPolicy(d.pop("submission_policy"))

        services_enabled = d.pop("services_enabled")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_bound_site_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        bound_site_id = _parse_bound_site_id(d.pop("bound_site_id", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["registry"] | Unset, d.pop("object", UNSET))
        if object_ != "registry" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'registry', got '{object_}'")

        post_v1_registries_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            name=name,
            purpose=purpose,
            description=description,
            category_root=category_root,
            entry_term=entry_term,
            tags=tags,
            visibility=visibility,
            submission_policy=submission_policy,
            services_enabled=services_enabled,
            created=created,
            updated=updated,
            sync_version=sync_version,
            bound_site_id=bound_site_id,
            deleted_at=deleted_at,
            object_=object_,
        )

        post_v1_registries_response_201.additional_properties = d
        return post_v1_registries_response_201

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
