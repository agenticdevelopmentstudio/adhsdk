from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProjectsByIdResearchResponse201")


@_attrs_define
class PostV1ProjectsByIdResearchResponse201:
    """
    Attributes:
        project_id (str):
        research (bool): always true on success
        object_ (Literal['project'] | Unset):
    """

    project_id: str
    research: bool
    object_: Literal["project"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        project_id = self.project_id

        research = self.research

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "project_id": project_id,
                "research": research,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        project_id = d.pop("project_id")

        research = d.pop("research")

        object_ = cast(Literal["project"] | Unset, d.pop("object", UNSET))
        if object_ != "project" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'project', got '{object_}'")

        post_v1_projects_by_id_research_response_201 = cls(
            project_id=project_id,
            research=research,
            object_=object_,
        )

        post_v1_projects_by_id_research_response_201.additional_properties = d
        return post_v1_projects_by_id_research_response_201

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
