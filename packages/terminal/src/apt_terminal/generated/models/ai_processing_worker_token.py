from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AiProcessingWorkerToken")


@_attrs_define
class AiProcessingWorkerToken:
    """
    Attributes:
        id (UUID):
        name (str):
        prefix (str): The first 12 characters, for recognising a token
        created_at (str):
        expires_at (None | str):
        last_used_at (None | str):
        nodes (list[str]): Ids of the registered nodes that last registered with this token
    """

    id: UUID
    name: str
    prefix: str
    created_at: str
    expires_at: None | str
    last_used_at: None | str
    nodes: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        name = self.name

        prefix = self.prefix

        created_at = self.created_at

        expires_at: None | str
        expires_at = self.expires_at

        last_used_at: None | str
        last_used_at = self.last_used_at

        nodes = self.nodes

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "prefix": prefix,
                "createdAt": created_at,
                "expiresAt": expires_at,
                "lastUsedAt": last_used_at,
                "nodes": nodes,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        name = d.pop("name")

        prefix = d.pop("prefix")

        created_at = d.pop("createdAt")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expiresAt"))

        def _parse_last_used_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_used_at = _parse_last_used_at(d.pop("lastUsedAt"))

        nodes = cast(list[str], d.pop("nodes"))

        ai_processing_worker_token = cls(
            id=id,
            name=name,
            prefix=prefix,
            created_at=created_at,
            expires_at=expires_at,
            last_used_at=last_used_at,
            nodes=nodes,
        )

        ai_processing_worker_token.additional_properties = d
        return ai_processing_worker_token

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
