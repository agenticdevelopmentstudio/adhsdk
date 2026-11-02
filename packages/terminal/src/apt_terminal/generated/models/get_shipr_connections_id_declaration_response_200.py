from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_shipr_connections_id_declaration_response_200_deployments_type_0_item import (
        GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item,
    )


T = TypeVar("T", bound="GetShiprConnectionsIdDeclarationResponse200")


@_attrs_define
class GetShiprConnectionsIdDeclarationResponse200:
    """
    Attributes:
        deployments (list[GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item] | None):
        fallback_slug (str): The `<name>-deployment` convention applied to this repository — what a run creates when
            nothing is declared, and what the form prepopulates its org and name fields from.
        note (str | Unset): Why the declaration was not usable, when it was present but not.
    """

    deployments: list[GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item] | None
    fallback_slug: str
    note: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        deployments: list[dict[str, Any]] | None
        if isinstance(self.deployments, list):
            deployments = []
            for deployments_type_0_item_data in self.deployments:
                deployments_type_0_item = deployments_type_0_item_data.to_dict()
                deployments.append(deployments_type_0_item)

        else:
            deployments = self.deployments

        fallback_slug = self.fallback_slug

        note = self.note

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "deployments": deployments,
                "fallbackSlug": fallback_slug,
            }
        )
        if note is not UNSET:
            field_dict["note"] = note

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_shipr_connections_id_declaration_response_200_deployments_type_0_item import (
            GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item,
        )

        d = dict(src_dict)

        def _parse_deployments(
            data: object,
        ) -> list[GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item] | None:
            if data is None:
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                deployments_type_0 = []
                _deployments_type_0 = data
                for deployments_type_0_item_data in _deployments_type_0:
                    deployments_type_0_item = (
                        GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item.from_dict(
                            deployments_type_0_item_data
                        )
                    )

                    deployments_type_0.append(deployments_type_0_item)

                return deployments_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                list[GetShiprConnectionsIdDeclarationResponse200DeploymentsType0Item] | None, data
            )

        deployments = _parse_deployments(d.pop("deployments"))

        fallback_slug = d.pop("fallbackSlug")

        note = d.pop("note", UNSET)

        get_shipr_connections_id_declaration_response_200 = cls(
            deployments=deployments,
            fallback_slug=fallback_slug,
            note=note,
        )

        get_shipr_connections_id_declaration_response_200.additional_properties = d
        return get_shipr_connections_id_declaration_response_200

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
