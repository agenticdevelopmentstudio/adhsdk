from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_project_projects_id_fields_body_type import PostProjectProjectsIdFieldsBodyType
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectProjectsIdFieldsBody")


@_attrs_define
class PostProjectProjectsIdFieldsBody:
    """
    Attributes:
        key (str):
        label (str):
        type_ (PostProjectProjectsIdFieldsBodyType):
        options (list[str] | Unset): required (non-empty) for a select field; omitted for every other type
        position (int | Unset): explicit field order; defaults to append (max+1)
    """

    key: str
    label: str
    type_: PostProjectProjectsIdFieldsBodyType
    options: list[str] | Unset = UNSET
    position: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        type_ = self.type_.value

        options: list[str] | Unset = UNSET
        if not isinstance(self.options, Unset):
            options = self.options

        position = self.position

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "type": type_,
            }
        )
        if options is not UNSET:
            field_dict["options"] = options
        if position is not UNSET:
            field_dict["position"] = position

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        type_ = PostProjectProjectsIdFieldsBodyType(d.pop("type"))

        options = cast(list[str], d.pop("options", UNSET))

        position = d.pop("position", UNSET)

        post_project_projects_id_fields_body = cls(
            key=key,
            label=label,
            type_=type_,
            options=options,
            position=position,
        )

        post_project_projects_id_fields_body.additional_properties = d
        return post_project_projects_id_fields_body

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
