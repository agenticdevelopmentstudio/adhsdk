from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_shipr_repos_by_id_status_body_environments_item import (
    PostV1ShiprReposByIdStatusBodyEnvironmentsItem,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_shipr_repos_by_id_status_body_options import (
        PostV1ShiprReposByIdStatusBodyOptions,
    )


T = TypeVar("T", bound="PostV1ShiprReposByIdStatusBody")


@_attrs_define
class PostV1ShiprReposByIdStatusBody:
    """
    Attributes:
        environments (list[PostV1ShiprReposByIdStatusBodyEnvironmentsItem] | Unset): Which environments a deploy walks,
            in pipeline order. Ignored by every other operation; required (non-empty) by deploy.
        options (PostV1ShiprReposByIdStatusBodyOptions | Unset): Per-operation arguments. Read defensively; unknown keys
            are ignored.
    """

    environments: list[PostV1ShiprReposByIdStatusBodyEnvironmentsItem] | Unset = UNSET
    options: PostV1ShiprReposByIdStatusBodyOptions | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        environments: list[str] | Unset = UNSET
        if not isinstance(self.environments, Unset):
            environments = []
            for environments_item_data in self.environments:
                environments_item = environments_item_data.value
                environments.append(environments_item)

        options: dict[str, Any] | Unset = UNSET
        if not isinstance(self.options, Unset):
            options = self.options.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if environments is not UNSET:
            field_dict["environments"] = environments
        if options is not UNSET:
            field_dict["options"] = options

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_shipr_repos_by_id_status_body_options import (
            PostV1ShiprReposByIdStatusBodyOptions,
        )

        d = dict(src_dict)
        _environments = d.pop("environments", UNSET)
        environments: list[PostV1ShiprReposByIdStatusBodyEnvironmentsItem] | Unset = UNSET
        if _environments is not UNSET:
            environments = []
            for environments_item_data in _environments:
                environments_item = PostV1ShiprReposByIdStatusBodyEnvironmentsItem(
                    environments_item_data
                )

                environments.append(environments_item)

        _options = d.pop("options", UNSET)
        options: PostV1ShiprReposByIdStatusBodyOptions | Unset
        if isinstance(_options, Unset):
            options = UNSET
        else:
            options = PostV1ShiprReposByIdStatusBodyOptions.from_dict(_options)

        post_v1_shipr_repos_by_id_status_body = cls(
            environments=environments,
            options=options,
        )

        post_v1_shipr_repos_by_id_status_body.additional_properties = d
        return post_v1_shipr_repos_by_id_status_body

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
