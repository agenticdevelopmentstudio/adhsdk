from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_registry_registries_body_submission_policy import (
    PostRegistryRegistriesBodySubmissionPolicy,
)
from ..models.post_registry_registries_body_visibility import PostRegistryRegistriesBodyVisibility
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostRegistryRegistriesBody")


@_attrs_define
class PostRegistryRegistriesBody:
    """
    Attributes:
        slug (str):
        name (str):
        purpose (str | Unset):
        description (str | Unset):
        category_root (str | Unset):
        entry_term (str | Unset):
        tags (list[str] | Unset): Discovery labels; trimmed and de-duplicated server-side.
        visibility (PostRegistryRegistriesBodyVisibility | Unset):
        submission_policy (PostRegistryRegistriesBodySubmissionPolicy | Unset):
        services_enabled (bool | Unset):
    """

    slug: str
    name: str
    purpose: str | Unset = UNSET
    description: str | Unset = UNSET
    category_root: str | Unset = UNSET
    entry_term: str | Unset = UNSET
    tags: list[str] | Unset = UNSET
    visibility: PostRegistryRegistriesBodyVisibility | Unset = UNSET
    submission_policy: PostRegistryRegistriesBodySubmissionPolicy | Unset = UNSET
    services_enabled: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        purpose = self.purpose

        description = self.description

        category_root = self.category_root

        entry_term = self.entry_term

        tags: list[str] | Unset = UNSET
        if not isinstance(self.tags, Unset):
            tags = self.tags

        visibility: str | Unset = UNSET
        if not isinstance(self.visibility, Unset):
            visibility = self.visibility.value

        submission_policy: str | Unset = UNSET
        if not isinstance(self.submission_policy, Unset):
            submission_policy = self.submission_policy.value

        services_enabled = self.services_enabled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
            }
        )
        if purpose is not UNSET:
            field_dict["purpose"] = purpose
        if description is not UNSET:
            field_dict["description"] = description
        if category_root is not UNSET:
            field_dict["categoryRoot"] = category_root
        if entry_term is not UNSET:
            field_dict["entryTerm"] = entry_term
        if tags is not UNSET:
            field_dict["tags"] = tags
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if submission_policy is not UNSET:
            field_dict["submissionPolicy"] = submission_policy
        if services_enabled is not UNSET:
            field_dict["servicesEnabled"] = services_enabled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        purpose = d.pop("purpose", UNSET)

        description = d.pop("description", UNSET)

        category_root = d.pop("categoryRoot", UNSET)

        entry_term = d.pop("entryTerm", UNSET)

        tags = cast(list[str], d.pop("tags", UNSET))

        _visibility = d.pop("visibility", UNSET)
        visibility: PostRegistryRegistriesBodyVisibility | Unset
        if isinstance(_visibility, Unset):
            visibility = UNSET
        else:
            visibility = PostRegistryRegistriesBodyVisibility(_visibility)

        _submission_policy = d.pop("submissionPolicy", UNSET)
        submission_policy: PostRegistryRegistriesBodySubmissionPolicy | Unset
        if isinstance(_submission_policy, Unset):
            submission_policy = UNSET
        else:
            submission_policy = PostRegistryRegistriesBodySubmissionPolicy(_submission_policy)

        services_enabled = d.pop("servicesEnabled", UNSET)

        post_registry_registries_body = cls(
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
        )

        post_registry_registries_body.additional_properties = d
        return post_registry_registries_body

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
