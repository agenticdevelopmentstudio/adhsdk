from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_projects_by_id_artifacts_body_direction import (
    PostV1ProjectsByIdArtifactsBodyDirection,
)
from ..models.post_v1_projects_by_id_artifacts_body_target_kind import (
    PostV1ProjectsByIdArtifactsBodyTargetKind,
)

T = TypeVar("T", bound="PostV1ProjectsByIdArtifactsBody")


@_attrs_define
class PostV1ProjectsByIdArtifactsBody:
    """
    Attributes:
        direction (PostV1ProjectsByIdArtifactsBodyDirection):
        target_kind (PostV1ProjectsByIdArtifactsBodyTargetKind): the target's registry, e.g. 'content.markdown'. Must be
            a kind the target registry knows (400 otherwise), and the target itself must exist within the PROJECT owner's
            reach (404 otherwise) — an unreachable id is indistinguishable from an absent one. GET
            /project/projects/{id}/attachable lists the ids that will be accepted.
        target_id (str):
    """

    direction: PostV1ProjectsByIdArtifactsBodyDirection
    target_kind: PostV1ProjectsByIdArtifactsBodyTargetKind
    target_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        direction = self.direction.value

        target_kind = self.target_kind.value

        target_id = self.target_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "direction": direction,
                "target_kind": target_kind,
                "target_id": target_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        direction = PostV1ProjectsByIdArtifactsBodyDirection(d.pop("direction"))

        target_kind = PostV1ProjectsByIdArtifactsBodyTargetKind(d.pop("target_kind"))

        target_id = d.pop("target_id")

        post_v1_projects_by_id_artifacts_body = cls(
            direction=direction,
            target_kind=target_kind,
            target_id=target_id,
        )

        post_v1_projects_by_id_artifacts_body.additional_properties = d
        return post_v1_projects_by_id_artifacts_body

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
