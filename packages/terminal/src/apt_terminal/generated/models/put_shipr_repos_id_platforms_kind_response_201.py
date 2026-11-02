from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PutShiprReposIdPlatformsKindResponse201")


@_attrs_define
class PutShiprReposIdPlatformsKindResponse201:
    """
    Attributes:
        kind (str):
        connection_id (str):
    """

    kind: str
    connection_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind

        connection_id = self.connection_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "connectionId": connection_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = d.pop("kind")

        connection_id = d.pop("connectionId")

        put_shipr_repos_id_platforms_kind_response_201 = cls(
            kind=kind,
            connection_id=connection_id,
        )

        put_shipr_repos_id_platforms_kind_response_201.additional_properties = d
        return put_shipr_repos_id_platforms_kind_response_201

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
