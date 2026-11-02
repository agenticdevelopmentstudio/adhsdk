from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_project_templates_body_kind import PostProjectTemplatesBodyKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_template_body import ProjectTemplateBody
    from ..models.work_item_template_body import WorkItemTemplateBody


T = TypeVar("T", bound="PostProjectTemplatesBody")


@_attrs_define
class PostProjectTemplatesBody:
    """
    Attributes:
        kind (PostProjectTemplatesBodyKind):
        name (str): unique among the workspace’s live templates OF THIS KIND (409 otherwise)
        body (ProjectTemplateBody | WorkItemTemplateBody): must match `kind` (400 otherwise), and must serialize to at
            most 16384 bytes. Validated STRICTLY — unlike a saved view’s opaque `config`, every key here BECOMES something,
            so an unrecognized one is refused rather than silently dropped.
        description (str | Unset):
    """

    kind: PostProjectTemplatesBodyKind
    name: str
    body: ProjectTemplateBody | WorkItemTemplateBody
    description: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.work_item_template_body import WorkItemTemplateBody

        kind = self.kind.value

        name = self.name

        body: dict[str, Any]
        if isinstance(self.body, WorkItemTemplateBody):
            body = self.body.to_dict()
        else:
            body = self.body.to_dict()

        description = self.description

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "name": name,
                "body": body,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_template_body import ProjectTemplateBody
        from ..models.work_item_template_body import WorkItemTemplateBody

        d = dict(src_dict)
        kind = PostProjectTemplatesBodyKind(d.pop("kind"))

        name = d.pop("name")

        def _parse_body(data: object) -> ProjectTemplateBody | WorkItemTemplateBody:
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

        body = _parse_body(d.pop("body"))

        description = d.pop("description", UNSET)

        post_project_templates_body = cls(
            kind=kind,
            name=name,
            body=body,
            description=description,
        )

        post_project_templates_body.additional_properties = d
        return post_project_templates_body

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
