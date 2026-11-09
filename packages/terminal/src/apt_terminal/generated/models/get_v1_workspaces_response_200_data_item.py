from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.workspace_type import WorkspaceType
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1WorkspacesResponse200DataItem")


@_attrs_define
class GetV1WorkspacesResponse200DataItem:
    """
    Attributes:
        slug (str): Routable workspace slug (caller-scoped)
        name (str):
        type_ (WorkspaceType):
        object_ (Literal['workspace'] | Unset):
    """

    slug: str
    name: str
    type_: WorkspaceType
    object_: Literal["workspace"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        type_ = self.type_.value

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "type": type_,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        type_ = WorkspaceType(d.pop("type"))

        object_ = cast(Literal["workspace"] | Unset, d.pop("object", UNSET))
        if object_ != "workspace" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'workspace', got '{object_}'")

        get_v1_workspaces_response_200_data_item = cls(
            slug=slug,
            name=name,
            type_=type_,
            object_=object_,
        )

        get_v1_workspaces_response_200_data_item.additional_properties = d
        return get_v1_workspaces_response_200_data_item

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
