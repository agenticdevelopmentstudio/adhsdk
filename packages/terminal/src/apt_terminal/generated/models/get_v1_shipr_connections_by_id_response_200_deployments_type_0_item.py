from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GetV1ShiprConnectionsByIdResponse200DeploymentsType0Item")


@_attrs_define
class GetV1ShiprConnectionsByIdResponse200DeploymentsType0Item:
    """
    Attributes:
        shard (str): The key in `[deployments]`.
        slug (str): owner/name of that shard’s mirror.
    """

    shard: str
    slug: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        shard = self.shard

        slug = self.slug

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "shard": shard,
                "slug": slug,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        shard = d.pop("shard")

        slug = d.pop("slug")

        get_v1_shipr_connections_by_id_response_200_deployments_type_0_item = cls(
            shard=shard,
            slug=slug,
        )

        get_v1_shipr_connections_by_id_response_200_deployments_type_0_item.additional_properties = d
        return get_v1_shipr_connections_by_id_response_200_deployments_type_0_item

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
