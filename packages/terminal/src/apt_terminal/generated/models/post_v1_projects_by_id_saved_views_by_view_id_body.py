from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_projects_by_id_saved_views_by_view_id_body_config import (
        PostV1ProjectsByIdSavedViewsByViewIdBodyConfig,
    )


T = TypeVar("T", bound="PostV1ProjectsByIdSavedViewsByViewIdBody")


@_attrs_define
class PostV1ProjectsByIdSavedViewsByViewIdBody:
    """
    Attributes:
        name (str | Unset):
        config (PostV1ProjectsByIdSavedViewsByViewIdBodyConfig | Unset): opaque client-defined view config (view id,
            filter, sort). Stored whole, never interpreted; must be a JSON object and serialize to at most 8192 bytes.
    """

    name: str | Unset = UNSET
    config: PostV1ProjectsByIdSavedViewsByViewIdBodyConfig | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        config: dict[str, Any] | Unset = UNSET
        if not isinstance(self.config, Unset):
            config = self.config.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if config is not UNSET:
            field_dict["config"] = config

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_projects_by_id_saved_views_by_view_id_body_config import (
            PostV1ProjectsByIdSavedViewsByViewIdBodyConfig,
        )

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        _config = d.pop("config", UNSET)
        config: PostV1ProjectsByIdSavedViewsByViewIdBodyConfig | Unset
        if isinstance(_config, Unset):
            config = UNSET
        else:
            config = PostV1ProjectsByIdSavedViewsByViewIdBodyConfig.from_dict(_config)

        post_v1_projects_by_id_saved_views_by_view_id_body = cls(
            name=name,
            config=config,
        )

        post_v1_projects_by_id_saved_views_by_view_id_body.additional_properties = d
        return post_v1_projects_by_id_saved_views_by_view_id_body

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
