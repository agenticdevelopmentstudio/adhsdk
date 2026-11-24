from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_artifact_direction import ProjectArtifactDirection
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.target_descriptor import TargetDescriptor


T = TypeVar("T", bound="GetV1ProjectsByIdArtifactsResponse200DataItem")


@_attrs_define
class GetV1ProjectsByIdArtifactsResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        direction (ProjectArtifactDirection): whether the project INGESTED or PRODUCED this target
        target_kind (str): the target's registry, e.g. 'content.markdown'
        target_id (str): the opaque target id
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        target (None | TargetDescriptor):
        deleted_at (None | str | Unset): set when un-linked (soft delete); null for a live link
        object_ (Literal['artifact'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    direction: ProjectArtifactDirection
    target_kind: str
    target_id: str
    created: int
    updated: int
    target: None | TargetDescriptor
    deleted_at: None | str | Unset = UNSET
    object_: Literal["artifact"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.target_descriptor import TargetDescriptor

        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        direction = self.direction.value

        target_kind = self.target_kind

        target_id = self.target_id

        created = self.created

        updated = self.updated

        target: dict[str, Any] | None
        if isinstance(self.target, TargetDescriptor):
            target = self.target.to_dict()
        else:
            target = self.target

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "direction": direction,
                "target_kind": target_kind,
                "target_id": target_id,
                "created": created,
                "updated": updated,
                "target": target,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.target_descriptor import TargetDescriptor

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        direction = ProjectArtifactDirection(d.pop("direction"))

        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_target(data: object) -> None | TargetDescriptor:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                target_type_0 = TargetDescriptor.from_dict(data)

                return target_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | TargetDescriptor, data)

        target = _parse_target(d.pop("target"))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["artifact"] | Unset, d.pop("object", UNSET))
        if object_ != "artifact" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'artifact', got '{object_}'")

        get_v1_projects_by_id_artifacts_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            direction=direction,
            target_kind=target_kind,
            target_id=target_id,
            created=created,
            updated=updated,
            target=target,
            deleted_at=deleted_at,
            object_=object_,
        )

        get_v1_projects_by_id_artifacts_response_200_data_item.additional_properties = d
        return get_v1_projects_by_id_artifacts_response_200_data_item

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
