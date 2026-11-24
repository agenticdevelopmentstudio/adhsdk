from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ProcessingWorkerTokensResponse200DataItem")


@_attrs_define
class GetV1ProcessingWorkerTokensResponse200DataItem:
    """
    Attributes:
        id (UUID):
        name (str):
        prefix (str): The first 12 characters, for recognising a token
        created (int): Unix timestamp, in seconds.
        expires_at (None | str):
        last_used_at (None | str):
        nodes (list[str]): Ids of the registered nodes that last registered with this token
        object_ (Literal['processing.worker_token'] | Unset):
    """

    id: UUID
    name: str
    prefix: str
    created: int
    expires_at: None | str
    last_used_at: None | str
    nodes: list[str]
    object_: Literal["processing.worker_token"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        name = self.name

        prefix = self.prefix

        created = self.created

        expires_at: None | str
        expires_at = self.expires_at

        last_used_at: None | str
        last_used_at = self.last_used_at

        nodes = self.nodes

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "prefix": prefix,
                "created": created,
                "expires_at": expires_at,
                "last_used_at": last_used_at,
                "nodes": nodes,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        name = d.pop("name")

        prefix = d.pop("prefix")

        created = d.pop("created")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expires_at"))

        def _parse_last_used_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_used_at = _parse_last_used_at(d.pop("last_used_at"))

        nodes = cast(list[str], d.pop("nodes"))

        object_ = cast(Literal["processing.worker_token"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.worker_token" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.worker_token', got '{object_}'")

        get_v1_processing_worker_tokens_response_200_data_item = cls(
            id=id,
            name=name,
            prefix=prefix,
            created=created,
            expires_at=expires_at,
            last_used_at=last_used_at,
            nodes=nodes,
            object_=object_,
        )

        get_v1_processing_worker_tokens_response_200_data_item.additional_properties = d
        return get_v1_processing_worker_tokens_response_200_data_item

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
