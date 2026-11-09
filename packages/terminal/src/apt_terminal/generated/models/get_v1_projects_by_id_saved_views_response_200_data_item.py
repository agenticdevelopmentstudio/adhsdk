from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_saved_view_config import ProjectSavedViewConfig


T = TypeVar("T", bound="GetV1ProjectsByIdSavedViewsResponse200DataItem")


@_attrs_define
class GetV1ProjectsByIdSavedViewsResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        name (str): unique among this project’s live views
        config (ProjectSavedViewConfig): opaque client-defined view config (view id, filter, sort). Stored whole, never
            interpreted; must be a JSON object and serialize to at most 8192 bytes.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        created_by (None | str | Unset): who saved it; confers nothing
        object_ (Literal['saved_view'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    name: str
    config: ProjectSavedViewConfig
    created: int
    updated: int
    created_by: None | str | Unset = UNSET
    object_: Literal["saved_view"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        name = self.name

        config = self.config.to_dict()

        created = self.created

        updated = self.updated

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "name": name,
                "config": config,
                "created": created,
                "updated": updated,
            }
        )
        if created_by is not UNSET:
            field_dict["created_by"] = created_by
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_saved_view_config import ProjectSavedViewConfig

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        name = d.pop("name")

        config = ProjectSavedViewConfig.from_dict(d.pop("config"))

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("created_by", UNSET))

        object_ = cast(Literal["saved_view"] | Unset, d.pop("object", UNSET))
        if object_ != "saved_view" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'saved_view', got '{object_}'")

        get_v1_projects_by_id_saved_views_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            name=name,
            config=config,
            created=created,
            updated=updated,
            created_by=created_by,
            object_=object_,
        )

        get_v1_projects_by_id_saved_views_response_200_data_item.additional_properties = d
        return get_v1_projects_by_id_saved_views_response_200_data_item

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
