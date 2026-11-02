from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_saved_view_config import ProjectSavedViewConfig


T = TypeVar("T", bound="ProjectSavedView")


@_attrs_define
class ProjectSavedView:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        name (str): unique among this project’s live views
        config (ProjectSavedViewConfig): opaque client-defined view config (view id, filter, sort). Stored whole, never
            interpreted; must be a JSON object and serialize to at most 8192 bytes.
        created_at (str):
        updated_at (str):
        created_by (None | str | Unset): who saved it; confers nothing
    """

    id: str
    ecosystem_id: str
    project_id: str
    name: str
    config: ProjectSavedViewConfig
    created_at: str
    updated_at: str
    created_by: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        name = self.name

        config = self.config.to_dict()

        created_at = self.created_at

        updated_at = self.updated_at

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "projectId": project_id,
                "name": name,
                "config": config,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if created_by is not UNSET:
            field_dict["createdBy"] = created_by

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_saved_view_config import ProjectSavedViewConfig

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        project_id = d.pop("projectId")

        name = d.pop("name")

        config = ProjectSavedViewConfig.from_dict(d.pop("config"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("createdBy", UNSET))

        project_saved_view = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            name=name,
            config=config,
            created_at=created_at,
            updated_at=updated_at,
            created_by=created_by,
        )

        project_saved_view.additional_properties = d
        return project_saved_view

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
