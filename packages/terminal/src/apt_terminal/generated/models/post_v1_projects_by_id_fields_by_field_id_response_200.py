from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_field_type import ProjectFieldType
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProjectsByIdFieldsByFieldIdResponse200")


@_attrs_define
class PostV1ProjectsByIdFieldsByFieldIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        key (str): stable identifier, unique within the project
        label (str):
        type_ (ProjectFieldType):
        position (int): field order (ascending)
        created (int): Unix timestamp, in seconds.
        options (list[str] | None | Unset): the choices for a select field (non-empty); null for every other type
        object_ (Literal['field'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    key: str
    label: str
    type_: ProjectFieldType
    position: int
    created: int
    options: list[str] | None | Unset = UNSET
    object_: Literal["field"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        key = self.key

        label = self.label

        type_ = self.type_.value

        position = self.position

        created = self.created

        options: list[str] | None | Unset
        if isinstance(self.options, Unset):
            options = UNSET
        elif isinstance(self.options, list):
            options = self.options

        else:
            options = self.options

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
                "type": type_,
                "position": position,
                "created": created,
            }
        )
        if options is not UNSET:
            field_dict["options"] = options
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

        type_ = ProjectFieldType(d.pop("type"))

        position = d.pop("position")

        created = d.pop("created")

        def _parse_options(data: object) -> list[str] | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                options_type_0 = cast(list[str], data)

                return options_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[str] | None | Unset, data)

        options = _parse_options(d.pop("options", UNSET))

        object_ = cast(Literal["field"] | Unset, d.pop("object", UNSET))
        if object_ != "field" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'field', got '{object_}'")

        post_v1_projects_by_id_fields_by_field_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            key=key,
            label=label,
            type_=type_,
            position=position,
            created=created,
            options=options,
            object_=object_,
        )

        post_v1_projects_by_id_fields_by_field_id_response_200.additional_properties = d
        return post_v1_projects_by_id_fields_by_field_id_response_200

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
