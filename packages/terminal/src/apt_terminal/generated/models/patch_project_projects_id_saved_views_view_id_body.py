from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.patch_project_projects_id_saved_views_view_id_body_config import (
        PatchProjectProjectsIdSavedViewsViewIdBodyConfig,
    )


T = TypeVar("T", bound="PatchProjectProjectsIdSavedViewsViewIdBody")


@_attrs_define
class PatchProjectProjectsIdSavedViewsViewIdBody:
    """
    Attributes:
        name (str | Unset):
        config (PatchProjectProjectsIdSavedViewsViewIdBodyConfig | Unset): opaque client-defined view config (view id,
            filter, sort). Stored whole, never interpreted; must be a JSON object and serialize to at most 8192 bytes.
    """

    name: str | Unset = UNSET
    config: PatchProjectProjectsIdSavedViewsViewIdBodyConfig | Unset = UNSET
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
        from ..models.patch_project_projects_id_saved_views_view_id_body_config import (
            PatchProjectProjectsIdSavedViewsViewIdBodyConfig,
        )

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        _config = d.pop("config", UNSET)
        config: PatchProjectProjectsIdSavedViewsViewIdBodyConfig | Unset
        if isinstance(_config, Unset):
            config = UNSET
        else:
            config = PatchProjectProjectsIdSavedViewsViewIdBodyConfig.from_dict(_config)

        patch_project_projects_id_saved_views_view_id_body = cls(
            name=name,
            config=config,
        )

        patch_project_projects_id_saved_views_view_id_body.additional_properties = d
        return patch_project_projects_id_saved_views_view_id_body

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
