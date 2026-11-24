from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_template_body import ProjectTemplateBody
    from ..models.work_item_template_body import WorkItemTemplateBody


T = TypeVar("T", bound="PostV1ProjectTemplatesByIdBody")


@_attrs_define
class PostV1ProjectTemplatesByIdBody:
    """Every key is optional and a patch that changes nothing returns the template unchanged. There is no `kind`: what a
    template makes is its identity.

        Attributes:
            name (str | Unset):
            description (str | Unset):
            body (ProjectTemplateBody | Unset | WorkItemTemplateBody): replaces the stored body outright; validated against
                the STORED kind
    """

    name: str | Unset = UNSET
    description: str | Unset = UNSET
    body: ProjectTemplateBody | Unset | WorkItemTemplateBody = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.work_item_template_body import WorkItemTemplateBody

        name = self.name

        description = self.description

        body: dict[str, Any] | Unset
        if isinstance(self.body, Unset):
            body = UNSET
        elif isinstance(self.body, WorkItemTemplateBody):
            body = self.body.to_dict()
        else:
            body = self.body.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if body is not UNSET:
            field_dict["body"] = body

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_template_body import ProjectTemplateBody
        from ..models.work_item_template_body import WorkItemTemplateBody

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        def _parse_body(data: object) -> ProjectTemplateBody | Unset | WorkItemTemplateBody:
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                body_type_0 = WorkItemTemplateBody.from_dict(data)

                return body_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            if not isinstance(data, dict):
                raise TypeError()
            body_type_1 = ProjectTemplateBody.from_dict(data)

            return body_type_1

        body = _parse_body(d.pop("body", UNSET))

        post_v1_project_templates_by_id_body = cls(
            name=name,
            description=description,
            body=body,
        )

        post_v1_project_templates_by_id_body.additional_properties = d
        return post_v1_project_templates_by_id_body

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
