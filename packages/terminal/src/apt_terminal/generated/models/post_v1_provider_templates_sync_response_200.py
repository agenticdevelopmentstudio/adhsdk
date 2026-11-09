from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.catalog_sync_outcome import CatalogSyncOutcome


T = TypeVar("T", bound="PostV1ProviderTemplatesSyncResponse200")


@_attrs_define
class PostV1ProviderTemplatesSyncResponse200:
    """
    Attributes:
        outcomes (list[CatalogSyncOutcome]):
        object_ (Literal['provider_template'] | Unset):
    """

    outcomes: list[CatalogSyncOutcome]
    object_: Literal["provider_template"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        outcomes = []
        for outcomes_item_data in self.outcomes:
            outcomes_item = outcomes_item_data.to_dict()
            outcomes.append(outcomes_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "outcomes": outcomes,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.catalog_sync_outcome import CatalogSyncOutcome

        d = dict(src_dict)
        outcomes = []
        _outcomes = d.pop("outcomes")
        for outcomes_item_data in _outcomes:
            outcomes_item = CatalogSyncOutcome.from_dict(outcomes_item_data)

            outcomes.append(outcomes_item)

        object_ = cast(Literal["provider_template"] | Unset, d.pop("object", UNSET))
        if object_ != "provider_template" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'provider_template', got '{object_}'")

        post_v1_provider_templates_sync_response_200 = cls(
            outcomes=outcomes,
            object_=object_,
        )

        post_v1_provider_templates_sync_response_200.additional_properties = d
        return post_v1_provider_templates_sync_response_200

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
