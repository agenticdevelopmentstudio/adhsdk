from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_status_category import ProjectStatusCategory
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ProjectsByIdStatusesResponse200DataItem")


@_attrs_define
class GetV1ProjectsByIdStatusesResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        key (str): stable identifier, unique within the project
        label (str):
        category (ProjectStatusCategory):
        position (int): column order (ascending)
        created (int): Unix timestamp, in seconds.
        object_ (Literal['statuse'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    key: str
    label: str
    category: ProjectStatusCategory
    position: int
    created: int
    object_: Literal["statuse"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        key = self.key

        label = self.label

        category = self.category.value

        position = self.position

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "key": key,
                "label": label,
                "category": category,
                "position": position,
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

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        key = d.pop("key")

        label = d.pop("label")

        category = ProjectStatusCategory(d.pop("category"))

        position = d.pop("position")

        created = d.pop("created")

        object_ = cast(Literal["statuse"] | Unset, d.pop("object", UNSET))
        if object_ != "statuse" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'statuse', got '{object_}'")

        get_v1_projects_by_id_statuses_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            key=key,
            label=label,
            category=category,
            position=position,
            created=created,
            object_=object_,
        )

        get_v1_projects_by_id_statuses_response_200_data_item.additional_properties = d
        return get_v1_projects_by_id_statuses_response_200_data_item

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
