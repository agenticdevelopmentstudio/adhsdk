from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_shipr_repos_id_platforms_response_200_platforms_item_kind import (
    GetShiprReposIdPlatformsResponse200PlatformsItemKind,
)

T = TypeVar("T", bound="GetShiprReposIdPlatformsResponse200PlatformsItem")


@_attrs_define
class GetShiprReposIdPlatformsResponse200PlatformsItem:
    """
    Attributes:
        kind (GetShiprReposIdPlatformsResponse200PlatformsItemKind):
        connection_id (str):
        label (None | str):
    """

    kind: GetShiprReposIdPlatformsResponse200PlatformsItemKind
    connection_id: str
    label: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        connection_id = self.connection_id

        label: None | str
        label = self.label

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "connectionId": connection_id,
                "label": label,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = GetShiprReposIdPlatformsResponse200PlatformsItemKind(d.pop("kind"))

        connection_id = d.pop("connectionId")

        def _parse_label(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        label = _parse_label(d.pop("label"))

        get_shipr_repos_id_platforms_response_200_platforms_item = cls(
            kind=kind,
            connection_id=connection_id,
            label=label,
        )

        get_shipr_repos_id_platforms_response_200_platforms_item.additional_properties = d
        return get_shipr_repos_id_platforms_response_200_platforms_item

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
