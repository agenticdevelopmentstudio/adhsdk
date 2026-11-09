from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_shipr_repos_by_id_platforms_response_200_data_item_kind import (
    GetV1ShiprReposByIdPlatformsResponse200DataItemKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ShiprReposByIdPlatformsResponse200DataItem")


@_attrs_define
class GetV1ShiprReposByIdPlatformsResponse200DataItem:
    """
    Attributes:
        kind (GetV1ShiprReposByIdPlatformsResponse200DataItemKind):
        connection_id (str):
        label (None | str):
        object_ (Literal['platform'] | Unset):
    """

    kind: GetV1ShiprReposByIdPlatformsResponse200DataItemKind
    connection_id: str
    label: None | str
    object_: Literal["platform"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        connection_id = self.connection_id

        label: None | str
        label = self.label

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "connection_id": connection_id,
                "label": label,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = GetV1ShiprReposByIdPlatformsResponse200DataItemKind(d.pop("kind"))

        connection_id = d.pop("connection_id")

        def _parse_label(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        label = _parse_label(d.pop("label"))

        object_ = cast(Literal["platform"] | Unset, d.pop("object", UNSET))
        if object_ != "platform" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'platform', got '{object_}'")

        get_v1_shipr_repos_by_id_platforms_response_200_data_item = cls(
            kind=kind,
            connection_id=connection_id,
            label=label,
            object_=object_,
        )

        get_v1_shipr_repos_by_id_platforms_response_200_data_item.additional_properties = d
        return get_v1_shipr_repos_by_id_platforms_response_200_data_item

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
