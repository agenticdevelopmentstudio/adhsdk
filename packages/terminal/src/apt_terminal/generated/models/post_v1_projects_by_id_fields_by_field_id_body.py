from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_projects_by_id_fields_by_field_id_body_type import (
    PostV1ProjectsByIdFieldsByFieldIdBodyType,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProjectsByIdFieldsByFieldIdBody")


@_attrs_define
class PostV1ProjectsByIdFieldsByFieldIdBody:
    """At least one mutable field is required (a no-op patch is a 400). `key` is immutable.

    Attributes:
        label (str | Unset):
        type_ (PostV1ProjectsByIdFieldsByFieldIdBodyType | Unset):
        options (list[str] | None | Unset): null clears the list; a select field requires a non-empty list on the
            effective (post-patch) type
        position (int | Unset):
    """

    label: str | Unset = UNSET
    type_: PostV1ProjectsByIdFieldsByFieldIdBodyType | Unset = UNSET
    options: list[str] | None | Unset = UNSET
    position: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        label = self.label

        type_: str | Unset = UNSET
        if not isinstance(self.type_, Unset):
            type_ = self.type_.value

        options: list[str] | None | Unset
        if isinstance(self.options, Unset):
            options = UNSET
        elif isinstance(self.options, list):
            options = self.options

        else:
            options = self.options

        position = self.position

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if label is not UNSET:
            field_dict["label"] = label
        if type_ is not UNSET:
            field_dict["type"] = type_
        if options is not UNSET:
            field_dict["options"] = options
        if position is not UNSET:
            field_dict["position"] = position

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        label = d.pop("label", UNSET)

        _type_ = d.pop("type", UNSET)
        type_: PostV1ProjectsByIdFieldsByFieldIdBodyType | Unset
        if isinstance(_type_, Unset):
            type_ = UNSET
        else:
            type_ = PostV1ProjectsByIdFieldsByFieldIdBodyType(_type_)

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

        position = d.pop("position", UNSET)

        post_v1_projects_by_id_fields_by_field_id_body = cls(
            label=label,
            type_=type_,
            options=options,
            position=position,
        )

        post_v1_projects_by_id_fields_by_field_id_body.additional_properties = d
        return post_v1_projects_by_id_fields_by_field_id_body

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
