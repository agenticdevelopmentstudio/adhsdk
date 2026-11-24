from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.get_v1_applications_by_id_response_200_schema_grants_grants_item import (
        GetV1ApplicationsByIdResponse200SchemaGrantsGrantsItem,
    )


T = TypeVar("T", bound="GetV1ApplicationsByIdResponse200SchemaGrants")


@_attrs_define
class GetV1ApplicationsByIdResponse200SchemaGrants:
    """
    Attributes:
        grants (list[GetV1ApplicationsByIdResponse200SchemaGrantsGrantsItem]):
    """

    grants: list[GetV1ApplicationsByIdResponse200SchemaGrantsGrantsItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        grants = []
        for grants_item_data in self.grants:
            grants_item = grants_item_data.to_dict()
            grants.append(grants_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "grants": grants,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_applications_by_id_response_200_schema_grants_grants_item import (
            GetV1ApplicationsByIdResponse200SchemaGrantsGrantsItem,
        )

        d = dict(src_dict)
        grants = []
        _grants = d.pop("grants")
        for grants_item_data in _grants:
            grants_item = GetV1ApplicationsByIdResponse200SchemaGrantsGrantsItem.from_dict(
                grants_item_data
            )

            grants.append(grants_item)

        get_v1_applications_by_id_response_200_schema_grants = cls(
            grants=grants,
        )

        get_v1_applications_by_id_response_200_schema_grants.additional_properties = d
        return get_v1_applications_by_id_response_200_schema_grants

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
