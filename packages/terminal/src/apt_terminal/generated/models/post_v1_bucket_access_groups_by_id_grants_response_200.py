from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.bucket_grant_target_type import BucketGrantTargetType
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BucketAccessGroupsByIdGrantsResponse200")


@_attrs_define
class PostV1BucketAccessGroupsByIdGrantsResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        access_group_id (str):
        target_type (BucketGrantTargetType):
        target_id (str):
        crud (str): comma-separated CRUD subset, e.g. 'C,R,U,D' or '' (none)
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        granted_by (None | str | Unset):
        object_ (Literal['grant'] | Unset):
    """

    id: str
    ecosystem_id: str
    access_group_id: str
    target_type: BucketGrantTargetType
    target_id: str
    crud: str
    created: int
    updated: int
    granted_by: None | str | Unset = UNSET
    object_: Literal["grant"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        access_group_id = self.access_group_id

        target_type = self.target_type.value

        target_id = self.target_id

        crud = self.crud

        created = self.created

        updated = self.updated

        granted_by: None | str | Unset
        if isinstance(self.granted_by, Unset):
            granted_by = UNSET
        else:
            granted_by = self.granted_by

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "access_group_id": access_group_id,
                "target_type": target_type,
                "target_id": target_id,
                "crud": crud,
                "created": created,
                "updated": updated,
            }
        )
        if granted_by is not UNSET:
            field_dict["granted_by"] = granted_by
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        access_group_id = d.pop("access_group_id")

        target_type = BucketGrantTargetType(d.pop("target_type"))

        target_id = d.pop("target_id")

        crud = d.pop("crud")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_granted_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        granted_by = _parse_granted_by(d.pop("granted_by", UNSET))

        object_ = cast(Literal["grant"] | Unset, d.pop("object", UNSET))
        if object_ != "grant" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'grant', got '{object_}'")

        post_v1_bucket_access_groups_by_id_grants_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            access_group_id=access_group_id,
            target_type=target_type,
            target_id=target_id,
            crud=crud,
            created=created,
            updated=updated,
            granted_by=granted_by,
            object_=object_,
        )

        post_v1_bucket_access_groups_by_id_grants_response_200.additional_properties = d
        return post_v1_bucket_access_groups_by_id_grants_response_200

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
